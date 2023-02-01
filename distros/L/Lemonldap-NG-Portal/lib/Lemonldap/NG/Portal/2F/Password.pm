# Password 2F second factor authentication
#
# This plugin handle authentications to ask the password for users that
# have registered their password
package Lemonldap::NG::Portal::2F::Password;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Common::Crypto;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_FORMEMPTY
  PE_SENDRESPONSE
  PE_BADCREDENTIALS
);

our $VERSION = '2.0.16';

extends 'Lemonldap::NG::Portal::Main::SecondFactor';
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has prefix => ( is => 'ro', default => 'password' );
has logo   => ( is => 'rw', default => 'password.png' );

has 'key' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return $self->conf->{password2fKey} || $self->conf->{key};
    }
);

has 'crypto' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        Lemonldap::NG::Common::Crypto->new( $self->key );
    }
);

sub init {
    my ($self) = @_;

    # If self registration is enabled and "activation" is just set to
    # "enabled", replace the rule to detect if user has registered its key
    $self->conf->{password2fActivation} = 'has2f("Password")'
      if (  $self->conf->{password2fSelfRegistration}
        and $self->conf->{password2fActivation} eq '1' );

    return $self->SUPER::init();
}

# RUNNING METHODS

sub run {
    my ( $self, $req, $token ) = @_;
    $self->logger->debug( $self->prefix . '2f: generate form' );

    # Prepare form
    my ( $checkLogins, $stayConnected ) = $self->getFormParams($req);
    my $tmp = $self->p->sendHtml(
        $req,
        'password2fcheck',
        params => {
            TOKEN         => $token,
            CHECKLOGINS   => $checkLogins,
            STAYCONNECTED => $stayConnected
        }
    );
    $self->logger->debug( $self->prefix . '2f: prepare verification' );

    $req->response($tmp);
    return PE_SENDRESPONSE;
}

sub verify {
    my ( $self, $req, $session ) = @_;
    my ( $password, $password_device, $secret );

    $self->logger->debug( $self->prefix . '2f: verification' );

    unless ( $password = $req->param('password') ) {
        $self->userLogger->error( $self->prefix . '2f: no value provided' );
        return PE_FORMEMPTY;
    }

    my @password_devices =
      $self->find2fDevicesByType( $req, $session, $self->type );
    unless ( $password_device = shift @password_devices ) {
        $self->logger->debug( $self->prefix . '2f: no password found' );
        return PE_ERROR;
    }

    unless ( $secret = $password_device->{_secret} ) {
        $self->logger->debug( $self->prefix . '2f: no password secret found' );
        return PE_ERROR;
    }

    if ( $password eq $self->crypto->decrypt($secret) ) {
        $self->userLogger->info( $self->prefix . '2f: correct' );
        return PE_OK;
    }
    else {
        $self->userLogger->notice( $self->prefix
              . '2f: invalid for '
              . $session->{ $self->conf->{whatToTrace} } );
        return PE_BADCREDENTIALS;
    }
}

1;
