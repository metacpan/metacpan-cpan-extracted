package Lemonldap::NG::Portal::2F::Mail2F;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_BADOTP
  PE_FORMEMPTY
  PE_MUSTHAVEMAIL
  PE_SENDRESPONSE
);

our $VERSION = '2.0.16';

extends qw(
  Lemonldap::NG::Portal::Lib::Code2F
  Lemonldap::NG::Portal::Lib::SMTP
);

# INITIALIZATION

# Prefix can overriden by sfExtra and is used for routes
has prefix => ( is => 'rw', default => 'mail' );

# Used to lookup config
has conf_type => ( is => 'ro', default => 'mail' );
has legend    => ( is => 'rw', default => 'enterMail2fCode' );

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{mail2fTimeout}
              || $_[0]->{conf}->{sfLoginTimeout}
              || $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);

has sessionKey => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return "destination" if $_[0]->is_registrable;
        return $_[0]->{conf}->{mail2fSessionKey}
          || $_[0]->{conf}->{mailSessionKey};
    }
);

# Mail2F always uses code generation
has code_activation => (
    is      => 'rw',
    lazy    => 1,
    default => sub {

        $_[0]->{conf}->{mail2fCodeRegex} || '\d{6}';
    }
);

sub init {
    my ($self) = @_;

    unless ( $self->sessionKey ) {
        $self->error(
            $self->prefix . '2f: missing session key parameter, aborting' );
        return 0;
    }

    return $self->SUPER::init();
}

# Return custom code when no email
sub run {
    my ( $self, $req, $token ) = @_;

    if ( !$self->is_registrable ) {
        my $dest = $req->{sessionInfo}->{ $self->sessionKey };
        unless ($dest) {
            $self->logger->error( $self->prefix
                  . '2f: could not find mail attribute for login '
                  . $req->{sessionInfo}->{_user} );
            return PE_MUSTHAVEMAIL;
        }
    }

    # Delegate code generation to SUPER
    return $self->SUPER::run( $req, $token );
}

sub sendCode {
    my ( $self, $req, $sessionInfo, $code ) = @_;
    my $dest = $sessionInfo->{ $self->sessionKey };

    if ( !$dest ) {
        $self->logger->error(
            $self->prefix . '2f: unable to find email recipient' );
        return 0;
    }

    # Template engine expects $req->sessionInfo to be populated
    # which is not the case during a resend
    $req->sessionInfo($sessionInfo);

    # Send mail
    if (
        $self->sendEmail(
            $req,
            subject       => $self->conf->{mail2fSubject},
            subject_trmsg => 'mail2fSubject',
            body          => $self->conf->{mail2fBody},
            body_template => 'mail_2fcode',
            dest          => $dest,
            params        => {
                code => $code,
            }
        )
      )
    {
        return 1;

    }
    else {
        $self->logger->error(
            $self->prefix . "2f: unable to send code to $dest" );
        return 0;
    }
}

sub verify_external {
    my ( $self, $req, $session, $usercode ) = @_;
    $self->logger->error(
        $self->prefix . '2f: verify_external is not supposed to be invoked' );
    return PE_ERROR;
}

1;
