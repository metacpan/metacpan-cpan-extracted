package Lemonldap::NG::Common::EmailTransport;

use strict;
use Email::Sender::Transport::SMTP qw();
use MIME::Entity;
use Email::Sender::Simple qw(sendmail);
use Email::Date::Format qw(email_date);

our $VERSION = '2.0.10';

sub new {
    my ( $class, $conf ) = @_;
    my $transport;
    my $smtpTls = $conf->{SMTPTLS};
    return undef
      unless ( $conf->{SMTPServer} );
    if (    $smtpTls
        and $Email::Sender::Transport::SMTP::VERSION < 1.300027 )
    {
        # Try to use Email::Sender::Transport::SMTPS
        eval { require Email::Sender::Transport::SMTPS; };

        # fall back to Email::Sender::Transport::SMTP if not available
        unless ($@) {
            $transport = Email::Sender::Transport::SMTPS->new(
                host => $conf->{SMTPServer},
                ( $conf->{SMTPPort} ? ( port => $conf->{SMTPPort} ) : () ),
                (
                    $conf->{SMTPAuthUser}
                    ? (
                        sasl_username => $conf->{SMTPAuthUser},
                        sasl_password => $conf->{SMTPAuthPass}
                      )
                    : ()
                ),
                ssl => $smtpTls,
            );
            return $transport;
        }
        else {
            if ( $smtpTls and $smtpTls eq "ssl" ) {
                $smtpTls = 1;
            }
            else {
                $smtpTls = 0;
            }
        }
    }
    $transport = Email::Sender::Transport::SMTP->new(
        host => $conf->{SMTPServer},
        ( $conf->{SMTPPort} ? ( port => $conf->{SMTPPort} ) : () ),
        (
            $conf->{SMTPAuthUser}
            ? (
                sasl_username => $conf->{SMTPAuthUser},
                sasl_password => $conf->{SMTPAuthPass}
              )
            : ()
        ),
        ( $smtpTls ? ( ssl => $smtpTls ) : () ),
        (
            $conf->{SMTPTLSOpts} ? ( ssl_options => $conf->{SMTPTLSOpts} )
            : ()
        ),
    );
    return $transport;
}

sub configTest {
    my ( $class, $conf ) = @_;
    my $res = 1;
    my $message;
    if ( $Email::Sender::Transport::SMTP::VERSION < 1.300027 ) {
        if ( $conf->{SMTPTLS} ) {
            $message = "Email::Sender < 1.3.00027 does not validate"
              . " server identity when using SMTPS, use at your own risks";
        }
        if ( $conf->{SMTPTLSOpts} and keys %{ $conf->{SMTPTLSOpts} } ) {
            $message =
                ( $message ? "$message. " : "" )
              . "Setting TLS parameters is not supported on "
              . "Email::Sender < 1.3.00027";
        }
        eval { require Email::Sender::Transport::SMTPS; };
        if ($@) {
            if ( $conf->{SMTPTLS} and $conf->{SMTPTLS} eq "starttls" ) {
                $message =
                    ( $message ? "$message. " : "" )
                  . "StartTLS is not supported, "
                  . "install Email::Sender::Transport::SMTPS";
            }
        }
    }
    return $res, $message;
}

sub sendTestMail {
    my ( $conf, $dest ) = @_;
    my $transport = Lemonldap::NG::Common::EmailTransport->new($conf);
    my $message   = MIME::Entity->build(
        From    => $conf->{mailFrom},
        To      => $dest,
        Subject => 'LemonLDAP::NG test email',
        Type    => 'TEXT',
        Data    => 'This test message was sent from the LemonLDAP::NG Manager',
        Type    => 'text/plain',
        Date    => email_date,
    );

    # Send the mail
    eval { sendmail( $message->stringify, { transport => $transport } ); };
    if ($@) {
        my $error = ( $@->isa('Throwable::Error') ? $@->message : $@ );
        die $error;
    }
}

1;
