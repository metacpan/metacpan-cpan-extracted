##@file
# SMTP common functions

##@class
# SMTP common functions
package Lemonldap::NG::Portal::_SMTP;

use strict;
use String::Random;
use MIME::Lite;
use MIME::Base64;
use Encode;

our $VERSION = '1.4.2';

## @method string gen_password(string regexp)
# Generate a complex password based on a regular expression
# @param regexp regular expression
# @return complex password
sub gen_password {
    my $self   = shift;
    my $regexp = shift;

    my $random = new String::Random;
    return $random->randregex($regexp);
}

## @method int send_mail(string mail, string subject, string body, string html)
# Send mail
# @param mail recipient address
# @param subject mail subject
# @param body mail body
# @param html optional set content type to HTML
# @return boolean result
sub send_mail {
    my ( $self, $mail, $subject, $body, $html ) = splice @_;

    # Set charset
    my $charset = $self->{mailCharset} ? $self->{mailCharset} : "utf-8";

    # Encode the body with the given charset
    $body    = encode( $charset, $body );
    $subject = encode( $charset, $subject );

    # Debug messages
    $self->lmLog( "SMTP From " . $self->{mailFrom}, 'debug' );
    $self->lmLog( "SMTP To " . $mail,               'debug' );
    $self->lmLog( "SMTP Subject " . $subject,       'debug' );
    $self->lmLog( "SMTP Body " . $body,             'debug' );
    $self->lmLog( "SMTP HTML flag " . ( $html ? "on" : "off" ), 'debug' );
    $self->lmLog( "SMTP Reply-To " . $self->{mailReplyTo}, 'debug' )
      if $self->{mailReplyTo};

    # Encode the subject
    $subject = encode_base64($subject);
    $subject =~ s/\s//g;
    $subject = "=?$charset?B?" . $subject . "?=";

    # Detect included images (cid)
    my %cid = ( $body =~ m/"cid:([^:]+):([^"]+)"/g );

    # Replace cid in body
    $body =~ s/"cid:([^:]+):([^"]+)"/"cid:$1"/g;

    eval {

        # Create message
        my $message;

        # HTML case
        if ($html) {
            $message = MIME::Lite->new(
                From       => $self->{mailFrom},
                To         => $mail,
                "Reply-To" => $self->{mailReplyTo},
                Subject    => $subject,
                Type       => 'multipart/related',
            );

            # Attach HTML message
            $message->attach(
                Type => "text/html; charset=$charset",
                Data => qq{$body},
            );

            # Attach included images
            foreach ( keys %cid ) {
                $message->attach(
                    Type => "image/" . ( $cid{$_} =~ m/\.(\w+)/ )[0],
                    Id => $_,
                    Path => $self->getApacheHtdocsPath() . "/" . $cid{$_},
                );
            }
        }

        # Plain text case
        else {
            $message = MIME::Lite->new(
                From       => $self->{mailFrom},
                To         => $mail,
                "Reply-To" => $self->{mailReplyTo},
                Subject    => $subject,
                Type       => 'TEXT',
                Data       => $body,
            );

            # Manage content type and charset
            $message->attr( "content-type"         => "text/plain" );
            $message->attr( "content-type.charset" => $charset );

        }

        # Send the mail
        $self->{SMTPServer}
          ? $message->send(
            "smtp", $self->{SMTPServer},
            AuthUser => $self->{SMTPAuthUser},
            AuthPass => $self->{SMTPAuthPass}
          )
          : $message->send();
    };
    if ($@) {
        $self->lmLog( "Send message failed: $@", 'error' );
        return 0;
    }

    return 1;
}

## @method string getMailSession(string user)
# Check if a mail session exists
# @param user the value of the user key in session
# @return the first session id found or nothing if no session
sub getMailSession {
    my ( $self, $user ) = splice @_;

    my $moduleOptions = $self->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->{globalStorage};
    my $module = "Lemonldap::NG::Common::Apache::Session";

    # Search on mail sessions
    my $sessions = $module->searchOn( $moduleOptions, "user", $user );

    # Browse found sessions to check if it's a mail session
    foreach my $id ( keys %$sessions ) {
        my $mailSession = $self->getApacheSession( $id, 1 );
        next unless ($mailSession);
        return $id if ( $mailSession->data->{_type} =~ /^mail$/ );
    }

    # No mail session found, return empty string
    return "";
}

## @method string getRegisterSession(string mail)
# Check if a register session exists
# @param mail the value of the mail key in session
# @return the first session id found or nothing if no session
sub getRegisterSession {
    my ( $self, $mail ) = splice @_;

    my $moduleOptions = $self->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->{globalStorage};
    my $module = "Lemonldap::NG::Common::Apache::Session";

    # Search on register sessions
    my $sessions = $module->searchOn( $moduleOptions, "mail", $mail );

    # Browse found sessions to check if it's a register session
    foreach my $id ( keys %$sessions ) {
        my $registerSession = $self->getApacheSession( $id, 1 );
        next unless ($registerSession);
        return $id if ( $registerSession->data->{_type} =~ /^register$/ );
    }

    # No register session found, return empty string
    return "";
}

1;
