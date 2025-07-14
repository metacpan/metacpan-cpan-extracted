###########################################
package Mail::DWIM;
###########################################

use strict;
use warnings;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(mail);
our $VERSION = "0.09";
our @HTML_MODULES = qw(HTML::FormatText HTML::TreeBuilder MIME::Lite);
our @ATTACH_MODULES = qw(File::MMagic MIME::Lite);

use YAML qw(LoadFile);
use Log::Log4perl qw(:easy);
use Config;
use Mail::Mailer;
use Sys::Hostname;
use File::Basename;
use POSIX qw(strftime);
use File::Spec;

my $error;

###########################################
sub mail {
###########################################
    my(@params) = @_;

    my $mailer = Mail::DWIM->new(@params);
    $mailer->send();
}

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my($homedir) = glob "~";

    my %defaults;

    my $self = {
        global_cfg_file => "/etc/maildwim",
        user_cfg_file   => "$homedir/.maildwim",
        transport       => "sendmail",
        raise_error     => 1,
        %options,
    };

      # Guess the 'from' address
    if(! exists $self->{from}) {
        my $user   = scalar getpwuid($<);
        my $domain = domain();
        $self->{from} = "$user\@$domain";
    }

      # Guess the 'date'
    if (!exists $self->{date}) {
        $self->{date} = strftime("%a, %e %b %Y %H:%M:%S %Z", localtime(time));
    }

    for my $cfg (qw(global_cfg_file user_cfg_file)) {
        if(-f $self->{$cfg}) {
            my $yml = LoadFile( $self->{$cfg} );
            if(defined $yml and ref $yml ne 'HASH') {
                  # Needs to be a hash, but YAML file can be empty (undef)
                LOGDIE "YAML file $self->{$cfg} format not a hash";
            }
              # merge with existing hash
            %defaults = (%defaults, %$yml) if defined $yml;
        }
    }

    %$self = (%$self, %defaults, %options);

    bless $self, $class;
}

###########################################
sub cmd_line_mail {
###########################################
    my($self) = @_;

    $self->{subject} = 'no subject' unless defined $self->{subject};

    my $mailer;
    $mailer = $self->{program} if defined $self->{program};
    $mailer = bin_find("mail") unless defined $mailer;

    open(PIPE, "|-", $mailer,
                    "-s", $self->{subject}, $self->{to},
        ) or LOGDIE "Opening $mailer failed: $!";

    print PIPE $self->{text};
    return close PIPE;
}

###########################################
sub send {
###########################################
    my($self, $evaled) = @_;

    if(!$self->{raise_error} && ! $evaled) {
        return $self->send_evaled();
    }

    my $msg =
          "Sending from=$self->{from} to=$self->{to} " .
          "subj=" . snip($self->{subject}, 20) . " " .
          "text=" . snip($self->{text}, 20) .
          "";

    my @options = ();

    if(0) {
    } elsif($self->{transport} eq "sendmail") {
        @options = ();
    } elsif($self->{transport} eq "smtp") {
          # Mail::SMTP likes it that way
        $ENV{ MAILADDRESS } = $self->{ from };

        LOGDIE "No smtp_server set" unless defined $self->{smtp_server};
        @options = ("smtp", Server => $self->{smtp_server});
        push @options, (Port => $self->{smtp_port}) 
          if exists $self->{smtp_port};
        $self->{to} = [split /\s*,\s*/, $self->{to}];

          # some smtp servers want SASL auth
        if( defined $self->{user} ) {
            require Authen::SASL;
            push @options, (
                Auth => [ $self->{user}, $self->{password} ],
                SSL => 1,
            );
        }
    } elsif($self->{transport} eq "mail") {
        return $self->cmd_line_mail();
    } else {
        LOGDIE "Unknown transport '$self->{transport}'";
    }

    my $mailer = Mail::Mailer->new(@options);
    my %headers;
    for (qw(from to cc bcc subject date)) {
        $headers{ucfirst($_)} = $self->{$_} if exists $self->{$_};
    }

    my $text = $self->{text};
    if($self->{html_compat}) {
        my $h;
        ($h, $text) = html_msg($text);
        %headers = (%headers, %$h);
    }

    if($self->{attach}) {
        my $h;
        ($h, $text) = attach_msg($text, @{$self->{attach}});
        %headers = (%headers, %$h);
    }

    if($ENV{MAIL_DWIM_TEST}) {
        DEBUG "Appending to test file $ENV{MAIL_DWIM_TEST}";
        my $txt;
        for (keys %headers) {
            $txt .= "$_: $headers{$_}\n" if defined $headers{$_};
        }
        $txt .= "\noptions @options\n\n";

        test_file_append($txt . $text);
        return 1;
    } else {
        DEBUG $msg;
    }

    $mailer->open(\%headers);
    print $mailer $text;
    $mailer->close();
}

###########################################
sub send_evaled {
###########################################
    my($self) = @_;

    eval {
        return $self->send(1);
    };

    if($@) {
        error($@);
        return undef;
    }
}

###########################################
sub error {
###########################################
    my($text) = @_;

    if(defined $text) {
        $error = $text;
    }

    return $error;
}

###########################################
sub test_file_append {
###########################################
    my($msg) = @_;

    open FILE, ">>$ENV{MAIL_DWIM_TEST}" or
        LOGDIE "Cannot open $ENV{MAIL_DWIM_TEST} ($!)";
    print FILE $msg, "\n\n";
    close FILE;
}

###########################################
sub html_requirements {
###########################################

    for (@HTML_MODULES) {
        eval "require $_";
        if($@) {
            return undef;
        }
    }

    1;
}

###########################################
sub attach_requirements {
###########################################

    for (@ATTACH_MODULES) {
        eval "require $_";
        if($@) {
            return undef;
        }
    }

    1;
}

###########################################
sub html_msg {
###########################################
    my($htmltext) = @_;

    if(! html_requirements()) {
        LOGDIE "Please install ",
               join(" ", @HTML_MODULES), " from CPAN";
    }

    my $tree = HTML::TreeBuilder->new();
    $tree->parse($htmltext);
    $tree->eof();
    my $formatter = HTML::FormatText->new();
    my $plaintext = $formatter->format($tree);

    my $msg = MIME::Lite->new(
      Type    => 'multipart/alternative',
    );

    $msg->attach(
      Type => 'text/plain',
      Data => $plaintext
    );

    $msg->attach(
        Type => 'text/html',
        Data => $htmltext,
    );

    my %headers;

    for (qw(Content-Transfer-Encoding Content-Type 
            MIME-version)) {
        $headers{$_} = $msg->attr($_);
    }

      # evil hack to compensate for MIME::Lite's shortcomings
    if( $headers{ "Content-Type" } !~ /boundary/ ) {
        $headers{ "Content-Type" } = 
            $headers{ "Content-Type" } . 
            qq{; boundary="} .
            $msg->{ SubAttrs }->{ "content-type" }->{ boundary } .
            qq{"};
    }

    return \%headers, $msg->body_as_string;
}

###########################################
sub attach_msg {
###########################################
    my($text, @files) = @_;

    if(! attach_requirements()) {
        LOGDIE "Please install ",
               join(" ", @ATTACH_MODULES), " from CPAN";
    }

    my $msg = MIME::Lite->new(
        Type => "multipart/mixed"
    );

    $msg->attach(Type     => "TEXT",
                 Data     => $text,
                );

    for my $file (@files) {
        my $mm = File::MMagic->new();
        my $type = $mm->checktype_filename($file);
        LOGDIE "Cannot determine mime type of $file" unless defined $type;

        $msg->attach(Type        => $type,
                     Path        => $file,
                     Filename    => basename($file),
                     Disposition => "attachment",
        );
    }

    my $headers = mime_lite_headers($msg);

    return $headers, $msg->body_as_string;
}

###########################################
sub mime_lite_headers {
###########################################
    my($mlite) = @_;

    my %wanted = map { lc($_) => $_ }
                     qw(Content-Transfer-Encoding Content-Type 
                        MIME-version);
    my %headers = ();

    for my $field (@{$mlite->fields}) {
        if(exists $wanted{$field->[0]}) {
            my($name, $value) = split /:\s*/, 
                                $mlite->fields_as_string([$field]), 2;
            $headers{$name} = $value;
        }
    }

    return(\%headers);
}

###########################################
sub header_ucfirst {
###########################################
    my($name) = @_;

    $name =~ s/^(\w)/uc($1)/g;
    $name =~ s/-(\w)/uc($1)/g;

    return $name;
}

###########################################
sub snip {
###########################################
    my($data, $maxlen) = @_;

    if(length $data <= $maxlen) {
        return lenformat($data);
    }

    $maxlen = 12 if $maxlen < 12;
    my $sniplen = int(($maxlen - 8) / 2);

    my $start   = substr($data,  0, $sniplen);
    my $end     = substr($data, -$sniplen);
    my $snipped = length($data) - 2*$sniplen;

    return lenformat("$start\[...]$end", length $data);
}

###########################################
sub lenformat {
###########################################
    my($data, $orglen) = @_;

    return "(" . ($orglen || length($data)) . ")[" .
        printable($data) . "]";
}

###########################################
sub printable {
###########################################
    my($data) = @_;

    $data =~ s/[^ \w.;!?@#$%^&*()+\\|~`'-,><[\]{}="]/./g;
    return $data;
}

###########################################
sub blurt {
###########################################
    my($data, $file) = @_;

    open FILE, ">$file" or die "Cannot open $file";
    print FILE $data;
    close FILE;
}

###########################################
sub slurp {
###########################################
    my($file) = @_;

    local($/);
    $/ = undef;

    open FILE, "<$file" or die "Cannot open $file";
    my $data = <FILE>;
    close FILE;
    return $data;
}

###########################################
sub domain {
###########################################

    my $domain = $Config{mydomain};

    if(defined $domain and length($domain)) {
        $domain =~ s/^\.//;
        return $domain;
    }

    eval { require Sys::Hostname; };
    if(! $@) {
        $domain = hostname();
        return $domain;
    }

    $domain = "localhost";

    return $domain;
}

######################################
sub bin_find {
######################################
    my($exe) = @_;

    for my $path (split /:/, $ENV{PATH}) {
        my $full = File::Spec->catfile($path, $exe);

        return $full if -x $full;
    }

    return undef;
}

1;

__END__

=head1 NAME

Mail::DWIM - Do-What-I-Mean Mailer

=head1 SYNOPSIS

    use Mail::DWIM qw(mail);

    mail(
      to      => 'foo@bar.com',
      subject => 'test message',
      text    => 'test message text'
    );

=head1 DESCRIPTION

C<Mail::DWIM> makes it easy to send email. You just name the
recipient, the subject line and the mail text and Mail::DWIM
does the rest.

This module isn't for processing massive amounts of email. It is
for sending casual emails without worrying about technical details.

C<Mail::DWIM> lets you store commonly used settings (like the default
sender email address or the transport mechanism) in a local
configuration file, so that you don't have to repeat settings in your
program code every time you want to send out an email. You are
certainly free to override the default settings if required.

C<Mail::DWIM> uses defaults wherever possible. So if you say

    use Mail::DWIM qw(mail);

    mail(
      to      => 'foo@bar.com',
      subject => 'test message',
      text    => 'test message text',
    );

that's enough for the mailer to send out an email to the specified
address. There's no C<from> field, so C<Mail::DWIM> uses 'user@domain.com'
where C<user> is the current Unix user and C<domain.com> is the domain
set in the Perl configuration (C<Config.pm>).
If you want to specify a different 'From:' field, go ahead:

    mail(
      from    => 'me@mydomain.com',
      to      => 'foo@bar.com',
      subject => 'test message',
      text    => 'test message text',
    );

By default, C<Mail::DWIM> connects to a running sendmail daemon to 
deliver the mail. But you can also specify an SMTP server:

    mail(
      to          => 'foo@bar.com',
      subject     => 'test message',
      text        => 'test message text',
      transport   => 'smtp',
      smtp_server => 'smtp.foobar.com',
      smtp_port   => 25, # defaults to 25
    );

If your SMTP server has SASL support, you can also specify a user name and
a password:

      user     => 'joeschmoe',
      password => 'top5ecret',

Note that the above will insist on using SSL/TLS as a transport protocol.

Or, if you prefer that Mail::DWIM uses the C<mail> Unix command line
utility, use 'mail' as a transport:

    mail(
      to          => 'foo@bar.com',
      subject     => 'test message',
      text        => 'test message text',
      transport   => 'mail',
      program     => '/usr/bin/mail',
    );

On a given system, these settings need to be specified only once and
put into a configuration file. All C<Mail::DWIM> instances running on 
this system will pick them up as default settings.

=head2 Configuration files

There is a global C<Mail::DWIM> configuration file in C</etc/maildwim>
with global settings and a user-specific file in C<~user/.maildwim>
which overrides global settings. Both files are optional, and
their format is YAML:

    # ~user/.maildwim
    from:      me@mydomain.com
    reply-to:  me@mydomain.com
    transport: sendmail

=head2 Error Handling

By default, C<Mail::DWIM> throws an error if something goes wrong
(aka: it dies). If that's not desirable and you want it to return
a true/false value code instead, set the C<raise_error> option to 
a false value:

    my $rc = mail(
      raise_error => 0,
      to          => 'foo@bar.com',
      ...
    );

    if(! $rc) {
        die "Release the hounds: ", Mail::DWIM::error();
    }

The detailed error message is available by calling Mail::DWIM::error().

=head2 Attaching files

If you want to include an image, a PDF files or some other attachment
in an email, use the C<attach> parameter 

    mail(
      to          => 'foo@bar.com',
      subject     => 'Pics of my new dog',
      attach      => ['doggie1.jpg', 'doggie2.jpg'],
      text        => "Hey, here's two cute pictures of Fritz :)",
    );

=head2 Sending HTML Emails

Many people hate HTML emails, but if you also attach a plaintext version 
for people with arcane email readers, everybody is happy. C<Mail::DWIM>
makes this easy with the C<html_compat> option:

    mail(
      to          => 'foo@bar.com',
      subject     => 'test message',
      html_compat => 1,
      text        => 'This is an <b>HTML</b> email.'
    );

This will create two attachments, the first one as plain text
(generated by HTML::Text to the best of its abilities), followed by
the specified HTML message marked as content-type C<text/html>. 
Non-HTML mail readers will pick up the first one, and Outlook-using
marketroids get fancy HTML. Everyone wins.

=head2 Test Mode

If the environment variable C<MAIL_DWIM_TEST> is set to a filename,
C<Mail::DWIM> prepares mail as usual, but doesn't send it off 
using the specified transport mechanism. Instead, it appends outgoing
mail ot the specified file. 

C<Mail::DWIM>'s test suite uses this mode to run a regression test
without needing an MTA.

=head2 Why another Mail Module?

The problem with other Mail:: or Email:: modules on CPAN is that they 
expose more options than the casual user needs. Why create a
mailer object, call its accessors and then its C<send> method if all I
want to do is call a function that works similarily to the Unix
C<mail> program?

C<Mail::DWIM> tries to be as 'Do-What-I-mean' as the venerable Unix
C<mail> command. Noboby has to read its documentation to use it:

    $ mail m@perlmeister.com
    Subject: foobar
    quack! quack!
    .
    Cc:
    CTRL-D

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

    2007, Mike Schilli <cpan@perlmeister.com>
    
=head1 LICENSE

Copyright 2007-2014 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

