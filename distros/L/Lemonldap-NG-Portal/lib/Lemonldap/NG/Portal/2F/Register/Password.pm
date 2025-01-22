# Self Password 2F registration
package Lemonldap::NG::Portal::2F::Register::Password;

use strict;
use Lemonldap::NG::Portal::Main::Constants 'PE_OK';
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Common::Crypto;

our $VERSION = '2.18.0';

extends 'Lemonldap::NG::Portal::2F::Register::Base';
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION
has logo     => ( is => 'rw', default => 'password.png' );
has prefix   => ( is => 'rw', default => 'password' );
has template => ( is => 'ro', default => 'password2fregister' );
has welcome  => ( is => 'ro', default => 'PE71' );
has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        my $timeout = $_[0]->{conf}->{sfRegisterTimeout}
          // $_[0]->{conf}->{formTimeout};
        $ott->timeout($timeout);
        return $ott;
    }
);

has key => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return $self->conf->{password2fKey} || $self->conf->{key};
    }
);

has crypto => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        Lemonldap::NG::Common::Crypto->new( $self->key );
    }
);

use constant supportedActions => {
    verify => "verify",
    delete => "delete",
};

# Verification that user has a valid password
sub verify {
    my ( $self, $req ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };

    return $self->failResponse( $req, 'csrfError', 400 )
      unless $self->checkCsrf($req);

    # Check Password
    my $password       = $req->param('password');
    my $passwordverify = $req->param('passwordverify');

    unless ( $password and $passwordverify ) {
        return $self->failResponse( $req, 'missingPassword', 200 );
    }

    # Invalid try is returned with a 200 code. Javascript will read error
    # and propose to retry
    if ( $password ne $passwordverify ) {
        return $self->failResponse( $req, 'PE34', 200 );
    }
    $self->logger->debug( $self->prefix . '2f: code verified' );

    # Now password is verified, let's store it in persistent data
    my $secret = $self->crypto->encrypt($password);

    # Reading existing 2F passwords
    my @password2f =
      $self->find2fDevicesByType( $req, $req->userData, $self->type );

    # Delete previous password if any
    if (@password2f) {
        if ( $self->del2fDevices( $req, $req->userData, \@password2f ) ) {
            $self->logger->debug(
                $self->prefix . "2f: old password(s) deleted" );
        }
        else {
            $self->logger->error(
                $self->prefix . "2f: unable to delete old password(s)" );
            return $self->failResponse( $req, 'serverError' );
        }
    }

    # Add a new one
    my $res = $self->registerDevice(
        $req,
        $req->userData,
        {
            _secret => $secret,
            name    => 'password',
            type    => $self->type,
            epoch   => time()
        }
    );
    if ( $res == PE_OK ) {
        return $self->successResponse( $req, { result => 1 } );
    }
    else {
        $self->logger->error( $self->prefix . "2f: unable to add password" );
        return $self->failResponse( $req, "PE$res" );
    }
}

1;
