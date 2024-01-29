# Self Password 2F registration
package Lemonldap::NG::Portal::2F::Register::Password;

use strict;
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

sub run {
    my ( $self, $req, $action ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };
    return $self->p->sendError( $req, 'PE82', 400 )
      unless $user;

    # Verification that user has a valid password
    if ( $action eq 'verify' ) {

        # Check Password
        my $password       = $req->param('password');
        my $passwordverify = $req->param('passwordverify');

        unless ( $password and $passwordverify ) {
            $self->userLogger->info(
                $self->prefix . "2f: registration -> empty validation form" );
            return $self->p->sendError( $req, 'missingPassword', 200 );
        }

        # Invalid try is returned with a 200 code. Javascript will read error
        # and propose to retry
        if ( $password ne $passwordverify ) {
            $self->userLogger->notice( $self->prefix
                  . "2f: registration -> password verification failed for $user"
            );
            return $self->p->sendError( $req, 'PE34', 200 );
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
                return $self->p->sendError( $req, 'serverError' );
            }
        }

        # Add a new one
        if (
            $self->add2fDevice(
                $req,
                $req->userData,
                {
                    _secret => $secret,
                    name    => 'password',
                    type    => $self->type,
                    epoch   => time()
                }
            )
          )
        {
            $self->markRegistered($req);
            return [
                200,
                [
                    'Content-Type'   => 'application/json',
                    'Content-Length' => 12,
                ],
                ['{"result":1}']
            ];
        }
        else {
            $self->logger->debug(
                $self->prefix . "2f: unable to add password" );
            return $self->p->sendError( $req, 'serverError' );
        }
    }
    elsif ( $action eq 'delete' ) {

        # Check if unregistration is allowed
        return $self->p->sendError( $req, 'notAuthorized', 400 )
          unless $self->conf->{password2fUserCanRemoveKey};

        my $epoch = $req->param('epoch')
          or return $self->p->sendError( $req,
            $self->prefix . '2f: "epoch" parameter is missing', 400 );

        if ( $self->del2fDevice( $req, $req->userData, $self->type, $epoch ) ) {
            $self->userLogger->notice(
                $self->prefix . "2f: password deleted for $user" );
            return [
                200,
                [
                    'Content-Type'   => 'application/json',
                    'Content-Length' => 12,
                ],
                ['{"result":1}']
            ];
        }
    }
    else {
        $self->logger->error( $self->prefix . "2f: unknown action ($action)" );
        return $self->p->sendError( $req, 'unknownAction', 400 );
    }
}

1;
