package Labyrinth::Mailer;

use warnings;
use strict;
use utf8;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Mailer - Mail Manager for Labyrinth 

=head1 SYNOPSIS

  use Labyrinth::Mailer;

  MailSend($template,%hash);

=head1 DESCRIPTION

The Mailer package contains generic functions used for sending mail messages.

=head1 EXPORT

  MailSend

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);
@EXPORT    = ( qw( MailSet MailSend MailSent HTMLSend ) );

# -------------------------------------
# Library Modules

use File::Basename;
use HTML::Entities;
use IO::File;
use MIME::Lite;
use MIME::Lite::TT::HTML;
use MIME::Types;
use Text::Wrap;

use Labyrinth::Audit;
use Labyrinth::Writer;
use Labyrinth::Variables;

# -------------------------------------
# Variables

my $mtypes = MIME::Types->new;

my %mailer;

# -------------------------------------
# The Subs

=head1 FUNCTIONS

=over 4

=item MailSet(%hash)

=item MailSend(%hash)

Hash table entries should contain TT variables used by the template. An email
address and template to use must be included.

=item MailSent

=item HTMLSend

=item HTMLSendX

=back

=cut

sub MailSet {
    my %hash  = @_;
    for(qw(mailsend logdir)) {
        $mailer{$_} = $hash{$_} if($hash{$_});
    }
}

sub MailSend {
    my %hash  = @_;
    my $errno = 0;

    $mailer{mailsend}   or return LogError("MailSend: mailsend not set");
    $mailer{logdir}     or return LogError("MailSend: logdir not set");

    my $template = $hash{template}          or return LogError("MailSend: template not set");
    my $email    = $hash{recipient_email}   or return LogError("MailSend: recipient_email not set");
    my $body;

#use Data::Dumper;
#LogDebug("MailSend: template=$template, email=$email, hash=".Dumper(\%hash));

    eval { $body = Transform($template,\%hash); };
    return LogError("MailSend: error=$@") if($@);
    eval { $body = decode_entities($body) };
#LogDebug("MailSend: body=$body");

    unless($hash{nowrap}) {
        $Text::Wrap::columns = 72;
        $body = wrap('', '', $body);
    }

    if($hash{output}) {
        my $fh = IO::File->new($hash{output},'a+')  or die "Cannot write to file [$hash{output}]: $!";
        $fh->binmode(':utf8');
        print $fh $body;
        print $fh "\n\n#-----\n";
        $fh->close;
        $mailer{result} = 1;
        $tvars{mailer}{result} = 1;
    } else {
        #my $cmd = qq!|:utf8 $mailer{mailsend} $email!;
        my $cmd = qq!| $mailer{mailsend} $email!;

        if(my $fh = IO::File->new($cmd)) {
            $fh->binmode(':utf8');
            print $fh $body;
            $fh->close;
            $mailer{result} = 1;
            $tvars{mailer}{result} = 1;
        } else {
            $mailer{result} = 0;
            $tvars{mailer}{result} = 0;
            $tvars{mailer}{error} = $!;
        }

        unless($mailer{result}) {
            my @files = sort glob("$mailer{logdir}/mail*.eml");
            my $num = 0;
            ($num) = ($files[-1] =~ /mail(\d+).eml/)    if(@files);
            $num++;
            my $file = sprintf "%s/mail%06d.eml", $mailer{logdir}, $num;
            LogDebug("MailSend - $file");
            my $fh = IO::File->new(">$file")    or die "Cannot write to file [$file]: $!";
            binmode($fh,':utf8');
            print $fh $body;
            print $fh "\n\nCommand: $cmd\n";
            print $fh "Error: $tvars{mailer}{error}\n";
            $fh->close;
            $mailer{file} = $file;
        }
    }
}

sub MailSent {
    return $mailer{result};
}

sub HTMLSend {
    my %hash  = @_;

    MIME::Lite->send('smtp', $settings{smtp}, Timeout=>60);
#    MIME::Lite->send('sendmail', "$settings{mailsend} $hash{to}", Timeout=>60);

    my $mail = MIME::Lite->new(
        From        => $hash{from},
        To          => $hash{to},
        Subject     => $hash{subject},
        Type        =>'multipart/related'
    );

    unless($mail) {
        LogError("HTMLSend: Error!");
        return;
    }

    if($hash{text}) {
        my $ref = Transform($hash{text},$hash{vars});
        my $text = $ref;

        $mail->attach(
            Type => 'text/text',
            Data => $text
        )   if($text);
    }

    if($hash{html}) {
        my $ref = Transform($hash{html},$hash{vars});
        my $html = $ref;


        for my $path ($html =~ m!href="([^"]+)"!g) {
            next if($path =~ m!$settings{protregex}!);
            my $newpath = "$settings{docroot}/$settings{webpath}/$path";
            $newpath =~ s!//+!/!g;
            $path =~ s!href="$path"!href="$newpath"!g;
        }

        $mail->attach(
            Type => 'text/html',
            Data => $html
        )   if($html);
    }

    for(@{$hash{attach}}) {
        if(/\.pdf$/i) {
            $mail->attach(Type => 'application/pdf  ', Encoding => 'base64', Path => $_, Filename => basename($_));
        } else {
            my ($type,$enc) = _mtype($_);
            $mail->attach(Type => $type, Encoding => $enc, Path => $_, Filename => basename($_));
        }
    }

    LogDebug("Mail=".$mail->as_string());
    eval {$mail->send;};
    if($@) {
        LogError("MailError: eval=[$@]") ;
        $mailer{result} = 0;
        $tvars{mailer}{result} = 0;
        $tvars{mailer}{error} = $@;
    } else {
        $mailer{result} = 1;
        $tvars{mailer}{result} = 1;
    }
}

sub HTMLSendX {
    my %hash  = @_;
    my $path = $settings{'templates'};

    my %config = (                              # provide config info
        RELATIVE        => 1,
        ABSOLUTE        => 1,
        INCLUDE_PATH    => $path,
        INTERPOLATE     => 0,
        POST_CHOMP      => 1,
        TRIM            => 1,
    );

    MIME::Lite->send('smtp', $settings{smtp}, Timeout=>60);
#    MIME::Lite->send('sendmail', "$settings{mailsend} $hash{to}", Timeout=>60);

    my $mail = MIME::Lite::TT::HTML->new(
        From        => $hash{from},
        To          => $hash{to},
        Subject     => $hash{subject},
#        Encoding    =>'base64',
        Encoding    =>'quoted-printable',
        Template    => {
            html => $hash{html},
            text => $hash{text},
        },
#        Charset     => 'utf8',
        TmplOptions => \%config,
        TmplParams  => \%tvars,
    );

    unless($mail) {
        LogError("HTMLSend: Error!");
        return;
    }

    for(@{$hash{attach}}) {
        if(/\.pdf$/i) {
            $mail->attach(Type => 'application/pdf  ', Encoding => 'base64', Path => $_, Filename => basename($_));
        } else {
            my ($type,$enc) = _mtype($_);
            $mail->attach(Type => $type, Encoding => $enc, Path => $_, Filename => basename($_));
        }
    }

    LogDebug("Mail=".$mail->as_string());
    eval { $mail->send };
    if($@) {
        LogError("MailError: eval=[$@]") ;
        $mailer{result} = 0;
        $tvars{mailer}{result} = 0;
        $tvars{mailer}{error} = $@;
    } else {
        $mailer{result} = 1;
        $tvars{mailer}{result} = 1;
    }
}

sub _mtype {
    my $file = shift;
    my $data = $mtypes->by_suffix($file);
    return @$data;
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
