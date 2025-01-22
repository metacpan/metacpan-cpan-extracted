# A generic 2FA module which registers a simple value into the psession
# This is meant to be used with sfExtra
package Lemonldap::NG::Portal::2F::Register::Generic;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Common::Crypto;
use Lemonldap::NG::Portal::Main::Constants 'PE_OK';

our $VERSION = '2.18.0';

extends 'Lemonldap::NG::Portal::2F::Register::Base';
with 'Lemonldap::NG::Portal::Lib::2fDevices';

# INITIALIZATION

has ott => (
    is      => 'ro',
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

# The verification module that we'll use
has verificationModule => (
    is       => 'rw',
    isa      => 'Lemonldap::NG::Portal::Lib::Code2F',
    weak_ref => 1,
);

# Overriden by sfExtra
has logo     => ( is => 'rw', default => 'generic.png' );
has prefix   => ( is => 'rw', default => 'generic' );
has template => ( is => 'ro', default => 'generic2fregister' );
has welcome  => ( is => 'ro', default => 'generic2fwelcome' );

use constant supportedActions => {
    sendcode => "sendcode",
    verify   => "verify",
    delete   => "delete",
};

sub sendcode {
    my ( $self, $req ) = @_;
    my $user    = $req->userData->{ $self->conf->{whatToTrace} };
    my $generic = $req->param('generic');

    unless ($generic) {
        return $self->failResponse( $req, 'PE79', 200 );
    }

    return $self->failResponse( $req, 'csrfError', 400 )
      unless $self->checkCsrf($req);

    # Validate format
    unless ( $self->validateFormat($generic) ) {
        my $error_label = $self->conf->{generic2fFormatErrorLabel}
          || 'generic2fFormatError';
        return $self->failResponse( $req, $error_label, 200 );
    }

    # Generate and send code

    # Save current session info into a token
    my $sessionInfo = { %{ $req->userData } };

    # Inject candidate value
    $sessionInfo->{destination} = $generic;
    my $token = $self->ott->createToken($sessionInfo);
    my $result =
      $self->verificationModule->challenge( $req, $sessionInfo, $token );
    return $self->failResponse( $req, 'serverError' ) unless $result;

    # Send response
    $self->userLogger->notice(
        $self->prefix . "2f: send verification code to $generic for $user" );
    return $self->successResponse( $req, { result => 1, token => $token } );
}

sub verify {

    my ( $self, $req ) = @_;

    return $self->failResponse( $req, 'csrfError', 400 )
      unless $self->checkCsrf($req);

    my $user        = $req->userData->{ $self->conf->{whatToTrace} };
    my $generic     = $req->param('generic');
    my $tokenid     = $req->param("token");
    my $genericcode = $req->param('genericcode');
    my $genericname =
      $self->checkNameSfa( $req, $self->prefix, $req->param('genericname') );
    return $self->failResponse( $req, 'badName', 200 ) unless $genericname;

    # Verify code
    my $token = $self->ott->getToken( $tokenid, 1 );
    my $res   = $self->verificationModule->verify_supplied_code( $req, $token,
        $genericcode );
    return $self->failResponse( $req, "PE$res", 400 )
      unless ( $res == PE_OK );

    # Now generic is verified, let's store it in persistent data
    # Reading existing 2FDevices
    my @generic2f =
      $self->find2fDevicesByType( $req, $req->userData, $self->prefix );

    # Delete previous generic if any
    if (@generic2f) {
        if ( $self->del2fDevices( $req, $req->userData, \@generic2f ) ) {
            $self->logger->debug( $self->prefix . "2f: old device(s) deleted" );
        }
        else {
            $self->logger->error(
                $self->prefix . "2f: unable to delete old device(s)" );
            return $self->failResponse( $req, 'serverError' );
        }
    }

    # Add a new one
    my $res = $self->registerDevice(
        $req,
        $req->userData,
        {
            _generic => $generic,
            name     => $genericname,
            type     => $self->prefix,
            epoch    => time()
        }
    );
    if ( $res == PE_OK ) {
        return $self->successResponse( $req, { result => 1 } );
    }
    else {
        $self->logger->error( $self->prefix . "2f: unable to add device" );
        return $self->failResponse( $req, "PE$res" );
    }
}

sub validateFormat {
    my ( $self, $generic ) = @_;
    my $format_regex = $self->{conf}->{generic2fFormatRegex};
    return 1 if ( !$format_regex );
    return scalar $generic =~ $format_regex;
}

1;

