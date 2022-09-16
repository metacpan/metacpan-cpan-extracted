##@file
# SMTP common functions

##@class
# SMTP common functions
package Lemonldap::NG::Portal::Lib::SMTP;

use strict;
use Mouse;
use JSON qw(from_json);
use MIME::Entity;
use Email::Sender::Simple qw(sendmail);
use Email::Date::Format qw(email_date);
use Lemonldap::NG::Common::EmailTransport;
use MIME::Base64;
use Encode;

our $VERSION = '2.0.12';

our $transport;

# PROPERTIES

has random => (
    is      => 'rw',
    default => sub {
        return Lemonldap::NG::Common::Crypto::srandom();
    }
);
has charset => (
    is      => 'rw',
    lazy    => 1,
    default => sub { return $_[0]->{conf}->{mailCharset} || 'utf-8' }
);
has transport => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return $transport if $transport;
        my $conf = $_[0]->{conf};
        $transport = Lemonldap::NG::Common::EmailTransport->new($conf);
        return $transport;
    },
);

sub loadMailTemplate {
    my ( $self, $req, $name, %prm ) = @_;

    # HTML::Template cache interferes with email translation (#1897)
    $prm{cache}                   = 0 unless defined $prm{cache};
    $prm{params}->{STATIC_PREFIX} = $self->p->staticPrefix;
    $prm{params}->{MAIN_LOGO}     = $self->conf->{portalMainLogo};
    my %extra =
        $self->p->can('tplParams')
      ? $self->p->tplParams($req)
      : ();
    $prm{params}->{$_} = $extra{$_} for keys %extra;

    return $self->loadTemplate( $req, $name, %prm );
}

sub translate {
    my ( $self, $req ) = @_;

    # Get language using llnglanguage cookie
    my $lang_code = $req->cookies->{llnglanguage} || 'en';
    my $json      = $self->conf->{templateDir} . "/common/mail/$lang_code.json";
    $json = $self->conf->{templateDir} . '/common/mail/en.json'
      unless ( -f $json );
    open F, '<', $json
      or die 'Installation error: '
      . $!
      . " ($self->{conf}->{templateDir}/$lang_code.json or $self->{conf}->{templateDir}/common/mail/en.json)";
    $json = join '', <F>;
    close F;
    my $lang = from_json( $json, { allow_nonref => 1 } );
    my $langOver =
      from_json( $self->p->getTrOver($req), { allow_nonref => 1 } );

    if ($langOver) {
        for my $k ( keys %{ $langOver->{all} || {} } ) {
            $lang->{$k} = $langOver->{all}->{$k};
        }
        for my $k ( keys %{ $langOver->{$lang_code} || {} } ) {
            $lang->{$k} = $langOver->{$lang_code}->{$k};
        }
    }
    return sub {
        ($_) = @_;
        $$_ =~ s/\s+trspan="(\w+?)"(.*?)>.*?</"$2>".($lang->{$1}||$1).'<'/gse;
        $$_ =~ s/^(\w+)$/$lang->{$1}||$1/es;
    };
}

# Generate a complex password based on a regular expression
# @param regexp regular expression
sub gen_password {
    my ( $self, $regexp ) = @_;
    return $self->random->randregex($regexp);
}

# Send mail
# @param mail recipient address
# @param subject mail subject
# @param body mail body
# @param html optional set content type to HTML
# @return boolean result
sub send_mail {
    my ( $self, $mail, $subject, $body, $html ) = @_;
    $self->logger->info("send_mail called to send \"$subject\" to $mail");

    # Encode the body with the given charset
    $body    = encode( $self->charset, decode( 'utf-8', $body ) );
    $subject = encode( $self->charset, decode( 'utf-8', $subject ) );

    # Debug messages
    $self->logger->debug( "SMTP From " . $self->conf->{mailFrom} );
    $self->logger->debug( "SMTP To " . $mail );
    $self->logger->debug( "SMTP Subject " . $subject );
    $self->logger->debug( "SMTP Body " . $body );
    $self->logger->debug( "SMTP HTML flag " . ( $html ? "on" : "off" ) );
    $self->logger->debug( "SMTP Reply-To " . $self->conf->{mailReplyTo} )
      if $self->conf->{mailReplyTo};

    # Encode the subject
    $subject = encode_base64( $subject, '' );
    $subject =~ s/\s//gs;
    $subject = '=?' . $self->charset . "?B?$subject?=";

    # Detect included images (cid)
    my %cid = ( $body =~ m/"cid:([^:]+):([^"]+)"/g );

    # Replace cid in body
    $body =~ s/"cid:([^:]+):([^"]+)"/"cid:$1"/g;

    eval {

        # Create message
        my $message;

        # HTML case
        if ($html) {
            $message = MIME::Entity->build(
                From => $self->conf->{mailFrom},
                To   => $mail,
                (
                    $self->conf->{mailReplyTo}
                    ? ( "Reply-To" => $self->conf->{mailReplyTo} )
                    : ()
                ),
                Subject => $subject,
                Type    => 'multipart/related',
                Date    => email_date,
            );

            # Attach HTML message
            $message->attach(
                Type => 'text/html; charset=' . $self->charset,
                Data => qq{$body},
            );

            # Attach included images
            foreach ( keys %cid ) {
                $message->attach(
                    Type => "image/" . ( $cid{$_} =~ m/\.(\w+)/ )[0],
                    Id   => $_,
                    Path => $self->conf->{templateDir} . "/"
                      . $self->conf->{portalSkin} . "/"
                      . $cid{$_},
                );
            }
        }

        # Plain text case
        else {
            $message = MIME::Entity->build(
                From       => $self->conf->{mailFrom},
                To         => $mail,
                "Reply-To" => $self->conf->{mailReplyTo},
                Subject    => $subject,
                Type       => 'TEXT',
                Data       => $body,
                Type       => 'text/plain',
                Charset    => $self->charset,
                Date       => email_date,
            );
        }

        # Send the mail
        sendmail( $message->stringify,
            ( $self->transport ? { transport => $self->transport } : () ) );
    };
    if ($@) {
        $self->logger->error( "Send message failed: "
              . ( $@->isa('Throwable::Error') ? $@->message : $@ ) );
        return 0;
    }

    return 1;
}

## @method string getMailSession(string user)
# Check if a mail session exists
# @param user the value of the user key in session
# @return the first session id found or nothing if no session
sub getMailSession {
    my ( $self, $user ) = @_;

    my $moduleOptions = $self->conf->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->conf->{globalStorage};
    my $module = "Lemonldap::NG::Common::Apache::Session";

    # Search on mail sessions
    my $sessions = $module->searchOn( $moduleOptions, "user", $user );

    # Browse found sessions to check if it's a mail session
    foreach my $id ( keys %$sessions ) {
        my $mailSession =
          $self->p->getApacheSession( $id, ( kind => "TOKEN" ) );
        next unless ($mailSession);
        return $mailSession if ( $mailSession->data->{_type} =~ /^mail$/ );
    }

    # No mail session found, return empty string
    return "";
}

## @method string getRegisterSession(string mail)
# Check if a register session exists
# @param mail the value of the mail key in session
# @return the first session id found or nothing if no session
sub getRegisterSession {
    my ( $self, $mail ) = @_;

    my $moduleOptions = $self->conf->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->conf->{globalStorage};
    my $module = "Lemonldap::NG::Common::Apache::Session";

    # Search on register sessions
    my $sessions = $module->searchOn( $moduleOptions, "mail", $mail );

    # Browse found sessions to check if it's a register session
    foreach my $id ( keys %$sessions ) {
        my $registerSession =
          $self->p->getApacheSession( $id, ( kind => "TOKEN" ) );
        next unless ($registerSession);
        return $id
          if (  $registerSession->data->{_type}
            and $registerSession->data->{_type} =~ /^register$/ );
    }

    # No register session found, return empty string
    return "";
}

1;
