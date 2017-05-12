###########################################
package Gaim::Log::Mailer;
###########################################

use strict;
use warnings;
use Gaim::Log::Parser 0.10;
use Gaim::Log::Finder;
use Log::Log4perl qw(:easy);
use URI::Find;
use Data::Throttler;
use Mail::DWIM qw(mail);
use Text::TermExtract;
use YAML qw(LoadFile);
use URI;

our $VERSION = "0.02";
our %SEEN;
my  $name = "gaimlogmailer";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my($home) = glob "~";

    my $self = {
        config_file => "$home/.$name.yml",
        conf => {
            min_age             => 3600,
            throttle_interval   => 3600,
            throttle_max_emails => 10,
            logfile             => undef,
            email_to            => undef,
            languages           => ['en'],
            exclude_words       => [],
        },
        %options,
    };

    $self->{base_dir} = "$home/.$name";
    if(! -d $self->{base_dir}) {
        mkdir $self->{base_dir} or 
            LOGDIE "Cannot create $self->{base_dir} ($!)";
    }

    if(-f $self->{config_file}) {
        my $conf = LoadFile( $self->{config_file} );
        foreach my $key (keys %$conf) {
            if(!exists $self->{conf}->{$key}) {
                LOGDIE "Unknown configuration parameter '$key' ",
                    "in $self->{config_file}";
            }
            $self->{conf}->{$key} = $conf->{$key};
        }

        if($conf->{exclude_words}) {
            $self->{conf}->{exclude_words} = 
                [split ' ', $conf->{exclude_words}];
        }

        if($conf->{languages}) {
            $self->{conf}->{languages} = 
                [split ' ', $conf->{languages}];
        }
    } else {
        LOGDIE "Cannot open conf file $self->{config_file} ($!)";
    }

    $self->{conf}->{exclude_hash} = { map { $_ => 1 } 
                                      @{ $self->{conf}->{exclude_words} } };

    if(!defined $self->{conf}->{email_to}) {
        LOGDIE "Mandatory parameter email_to missing in configuration.";
    }

    $self->{throttler} = Data::Throttler->new(
        db_file => "$self->{base_dir}/throttle",
            interval  => $self->{conf}->{throttle_interval},
            max_items => $self->{conf}->{throttle_max_emails},
    );

    dbmopen %SEEN, "$self->{base_dir}/seen", 0644 or
        LOGDIE "Cannot open dbm file $self->{base_dir}/seen ($!)";

    $SIG{TERM} = sub { 
        INFO "Exiting";
        dbmclose %SEEN;
        exit 0;
    };

    bless $self, $class;
}

###########################################
sub process {
###########################################
    my($self) = @_;

    my $finder = Gaim::Log::Finder->new(
      callback => sub {
        my($self, $file, $protocol, $from, $to) = @_;
  
        return 1 if $from eq $to;
  
        my $mtime = (stat $file)[9];
        my $age = time() - $mtime;
  
        return 1 if $SEEN{$file} and
                    $SEEN{$file} == $mtime;
  
        if($age < $self->{mailer}->{conf}->{min_age}) {
            INFO "$file: Too recent ($age)";
            return 1;
        }
  
        INFO "Processing log file: $file";
        my($subject, $formatted, $epoch) = $self->{mailer}->examine($file);

        DEBUG "subject: $subject";
        DEBUG "formatted: $formatted";
        DEBUG "epoch: $epoch";

  
        if(! $self->{mailer}->email_send($epoch, $to, $subject, $formatted)) {
            DEBUG "Email couldn't be sent. Exiting";
            exit 0;
        }
        $SEEN{$file} = $mtime;
  });

  $finder->{mailer} = $self;
  $finder->find();
}

###########################################
sub examine {
###########################################
    my($self, $file) = @_;
  
    my $extr = Text::TermExtract->new( 
            languages => $self->{conf}->{languages} );

    $extr->exclude( $self->{conf}->{exclude_words} );

    my $parser = Gaim::Log::Parser->new(
      file => $file,
    );

        # Search+delete URL processor
    my @hosts = ();
    my $urifind = URI::Find->new(sub {push @hosts, $_[0]->host(); 
                                      return "";});
  
    my $content  = "";
    my $urifound = 0;
  
    while(my $m = $parser->next_message()) {
        $content .= " " . $m->content();
    }

    $urifound = $urifind->find(\$content);
    $content = " " unless length $content;

    my @words = $extr->terms_extract( $content, {max => 20} );

    my $char = "";
    my $subj = ($urifound ? "*L* $hosts[0] " : "");

    while(@words and 
          length($subj) + length($char . $words[0]) <= 70) {
        $subj .= $char .  shift @words;
        $char = ", ";
    }

    return($subj, $parser->as_string(), $parser->{dt}->epoch());
}

###########################################
sub email_send {
###########################################
  my($self, $epoch, $from, $subject, $text) = @_;

  if(!$self->{throttler}->try_push()) {
      ERROR "Email throttled.";
      return undef;
  }

  if($self->{fake_email}) {
      print <<EOT;
==========================================================================
From: $from
To:   $self->{conf}->{email_to}
Subject: [gaim $from] $subject

$text
==========================================================================
EOT
      return 1;
  }

  INFO "Sending email '$subject'";

  mail(
    from    => "$from\@gaim",
    to      => $self->{conf}->{email_to},
    subject => "[gaim] " . $subject,
    text    => "From: $from\n" .
               "Date: " . 
               (scalar localtime $epoch) . 
               "\n\n$text",
  );

  return 1;
}

  
1;

__END__

=head1 NAME

Gaim::Log::Mailer - Have your Gaim/Pidgin logs mailed to you

=head1 SYNOPSIS

    use Gaim::Log::Mailer;
    my $mailer = Gaim::Log::Mailer->new();
    $mailer->process();

    # ~/.gaimlogmailer.yml
     logfile:  /tmp/gaimlogmailer.log
     email_to: foo@bar.com
     min_age:  3600
     throttle_interval:   3600
     throttle_max_emails: 10

=head1 DESCRIPTION

Have you ever wanted to look at the content of an IM conversation you had
earlier? But you couldn't, because you had the conversation on a different
system than the one you're using now? You need to centralize your 
Gaim/Pidgin logs.

Gaim::Log::Mailer figures out if you have new IM conversations
in your Gaim log directory and mails them to your account, so you have
them available in your email, which you can check, wherever you are.

This module comes with a script C<gaimlogmailer> which just reads in
a YAML configuration file (usually ~/.gaimlogmailer.yml>, then processes
availabe logs up to an adjustable threshold, sends them nicely formatted
to the specified email address and then exits.

It is recommended that you run this script in a cronjob, to make sure all
new IM conversations are picked up and forwarded. For example, here's 
a cronjob that runs C<gaimlogmailer> every hour on the 13th minute:

    $ crontab -l
    13 * * * * /path/to/gaimlogmailer

=head2 Configuration

The configuration file C<~/.gaimlogmailer.yml> specifies a number
of parameters that C<gaimlogmailer> needs to operate. They are given
in YAML format, which basically just means

    # comment
    key: value

and comment lines are ignored. Strings need to be enclosed in quotes.
For details on this format, check http://yaml.org.

Here are the parameters in detail:

=over 4

=item email_to

(Mandatory) The email address the script sends the log to.

=item logfile

(Optional) The log file where the script logs all activity, using Log4perl.

    logfile: "/tmp/gaimlogmailer.log"

(Note the quotes, YAML insists on them here).

=item min_age

(Optional, defaults to 3600). The minimum number of seconds a log file
needs to stay untouched by the Gaim application before the mailer
processes it. Reason for this is that there is no way to figure out 
if Gaim is done writing a log
file or if it will still append to it at some point. 

The mailer knows this and won't mail a file that has
a modification date younger than C<min_age> seconds in the past to make
sure no half-written log files are processed. However, this method isn't
bullet-proof, and the mailer deals with this situation: if the mailer 
notices that an already processed file has new data, it will process
it again. This way, you'll get two emails, so make sure this happens
rarely and choose min_age accordingly and wisely.

=item throttle_interval

(Optional, defaults to 3600/10).
A new installation of gaimlogmailer might find thousands of logfiles which
need to be mailed out one by one. To avoid overwhelming the mail system
or triggering spam filters, the number of emails can be limited to 
C<throttle_max_emails> per C<throttle_interval>.

For example, if you want gaimlogmailer to only send a maximum of 10
emails per hour, set

    throttle_interval:   3600
    throttle_max_emails: 10

in your configuration file. Even if the script is rate-limited in this
way, it'll pick up slowly and handle all logs eventually.

=item throttle_max_emails

See C<throttle_interval>.

=item exclude_words

A list of blank-separated words 

    # configuration file
    exclude_words: maybe thanks thx doesn hey put already

=item languages

A blank-separated list of languages the term extractor should try.

    # Try English and German
    languages: en de

=back

=head2 Mail Preferences

Gaim::Log::Mailer uses Mail::DWIM to send out mail. By default, it uses
a sendmail daemon on the local machine, if you want something else, you
can change the local .maildwim file and specify a different transport
(e.g. SMTP). See the Mail::DWIM documentation for details.

=head2 References

This module is based on an article I wrote for the German Linux Magazine,
where IM logs were sent to an IMAP server:
http://www.linux-magazin.de/heft_abo/ausgaben/2007/06/gespraechsprotokolle

=head1 LEGALESE

Copyright 2008 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2008, Mike Schilli <cpan@perlmeister.com>
