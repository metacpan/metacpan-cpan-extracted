# Self WebAuthn registration
package Lemonldap::NG::Portal::2F::Register::WebAuthn;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use MIME::Base64 qw(encode_base64url decode_base64url);
use Crypt::URandom;

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Main::Plugin';
with 'Lemonldap::NG::Portal::Lib::WebAuthn';

# INITIALIZATION

has prefix   => ( is => 'rw', default => 'webauthn' );
has template => ( is => 'ro', default => 'webauthn2fregister' );
has welcome  => ( is => 'ro', default => 'webauthn2fWelcome' );
has logo     => ( is => 'rw', default => 'webauthn.png' );
has ott      => (
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

has displayname_attr => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
             $self->conf->{webauthnDisplayNameAttr}
          || $self->conf->{portalUserAttr}
          || $self->conf->{whatToTrace}
          || '_user';
    }
);

has rpName => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->conf->{webauthnRpName} || "LemonLDAP::NG";
    }
);

sub init { return 1; }

# RUNNING METHODS

# Return a Base64url encoded user handle
sub getRegistrationUserHandle {
    my ( $self, $req ) = @_;

    my $current_user_handle = $self->getUserHandle( $req, $req->userData );
    if ($current_user_handle) {
        return $current_user_handle;
    }
    else {
        my $new_user_handle = $self->_generate_user_handle;
        $self->setUserHandle( $req, $new_user_handle );
        return $new_user_handle;
    }
}

# https://www.w3.org/TR/webauthn-2/#sctn-user-handle-privacy
# It is RECOMMENDED to let the user handle be 64 random bytes, and store this
# value in the user’s account.
sub _generate_user_handle {
    my ($self) = @_;
    return encode_base64url( Crypt::URandom::urandom(64) );
}

sub _registrationchallenge {
    my ( $self, $req, $user ) = @_;

    my @_2fDevices = $self->find2fByType( $req, $req->userData );

    # Check if user can register one more 2F device
    my $size    = @_2fDevices;
    my $maxSize = $self->conf->{max2FDevices};
    $self->logger->debug("Registered 2F Device(s): $size / $maxSize");
    if ( $size >= $maxSize ) {
        $self->userLogger->warn("Max number of 2F devices is reached");
        return $self->p->sendError( $req, 'maxNumberof2FDevicesReached', 400 );
    }

    my $challenge_base64 = encode_base64url( Crypt::URandom::urandom(32) );

    # Challenge is persisted on the server
    my $token = $self->ott->createToken( {
            registration_options => {
                challenge => $challenge_base64,
            }
        }
    );

    my $displayName      = $req->userData->{ $self->displayname_attr } || $user;
    my $userVerification = $self->conf->{webauthn2fUserVerification};

    my $request = {
        rp => {
            name => $self->rpName,
        },
        user => {
            name        => $user,
            id          => $self->getRegistrationUserHandle($req),
            displayName => $displayName,
        },
        challenge              => $challenge_base64,
        pubKeyCredParams       => [],
        authenticatorSelection => { (
                $userVerification
                ? ( userVerification => $userVerification )
                : ()
            )
        }
    };

    $self->logger->debug( "Register parameters " . to_json($request) );
    return $self->p->sendJSONresponse( $req,
        { request => $request, state_id => $token } );
}

sub _registration {
    my ( $self, $req, $user ) = @_;

    # Recover creation parameters, including challenge
    my $state_id = $req->param('state_id');
    unless ($state_id) {
        $self->logger->error("Could not find state ID in WebAuthn response");
        return $self->p->sendError( $req, 'Invalid response', 400 );
    }
    my $state_data;
    unless ( $state_data = $self->ott->getToken($state_id) ) {
        $self->logger->error(
            "Expired or invalid state ID in WebAuthn response: $state_id");
        return $self->p->sendError( $req, 'PE82', 400 );
    }
    my $registration_options = ( $state_data->{registration_options} );
    return $self->p->sendError( $req,
        'Registration options missing from state data', 400 )
      unless ($registration_options);

    # Data required for WebAuthn verification
    my $credential_json = $req->param('credential');
    $self->logger->debug("Get registered credential data $credential_json");

    return $self->p->sendError( $req, 'Missing credential parameter', 400 )
      unless ($credential_json);

    my $validation = eval {
        $self->validateCredential( $req, $registration_options,
            $credential_json );
    };
    if ($@) {
        $self->logger->error("Credential validation error: $@");
        return $self->p->sendError( $req, "webAuthnRegisterFailed", 400 );
    }

    my $credential_id     = $validation->{credential_id};
    my $credential_pubkey = $validation->{credential_pubkey};
    my $signature_count   = $validation->{signature_count};

    $self->logger->debug( "Registering new credential : \n" . "ID: "
          . $credential_id . "\n"
          . "Public key "
          . $credential_pubkey . "\n"
          . "Signature count "
          . $signature_count
          . "\n" );

    if (
        $self->find2fByKey(
            $req, $req->userData, $self->type,
            "_credentialId", $credential_id
        )
      )
    {
        return $self->p->sendError( $req, 'webauthnAlreadyRegistered', 400 );
    }

    my $keyName = $req->param('keyName');
    my $epoch   = time();

    # Set default name if empty, check characters and truncate name if too long
    $keyName ||= $epoch;
    unless ( $keyName =~ /^[\w]+$/ ) {
        $self->userLogger->error('WebAuthn name with bad character(s)');
        return $self->p->sendError( $req, 'badName', 200 );
    }
    $keyName = substr( $keyName, 0, $self->conf->{max2FDevicesNameLength} );
    $self->logger->debug("Key name: $keyName");

    if (
        $self->add2fDevice(
            $req,
            $req->userData,
            {
                type                 => $self->type,
                name                 => $keyName,
                _credentialId        => $credential_id,
                _credentialPublicKey => $credential_pubkey,
                _signCount           => $signature_count,
                epoch                => $epoch
            }
        )
      )
    {
        $self->userLogger->notice(
            "Webauthn key registration of $keyName succeeds for $user");

        return $self->p->sendJSONresponse( $req, { result => 1 } );
    }
    else {
        return $self->p->sendError( $req, 'Server Error', 500 );
    }

}

sub _verificationchallenge {
    my ( $self, $req, $user ) = @_;

    $self->logger->debug('Verification challenge req');

    my $request = $self->generateChallenge( $req, $req->userData );

    unless ($request) {
        return $self->p->sendError( $req, "No registered devices", 400 );
    }

    # Request is persisted on the server
    my $token = $self->ott->createToken( {
            authentication_options => $request,
        }
    );

    $self->logger->debug( "Authentication parameters: " . to_json($request) );
    return $self->p->sendJSONresponse( $req,
        { request => $request, state_id => $token } );
}

sub _verification {
    my ( $self, $req, $user ) = @_;

    my $credential_json = $req->param('credential');

    return $self->p->sendError( $req, 'Missing credential parameter', 400 )
      unless ($credential_json);

    my $state_id = $req->param('state_id');
    unless ($state_id) {
        $self->logger->error(
            "Could not find state ID in WebAuthn response: $credential_json");
        return $self->p->sendError( $req, 'Invalid response', 400 );
    }

    # Recover challenge
    my $state_data;
    unless ( $state_data = $self->ott->getToken($state_id) ) {
        $self->logger->error(
            "Expired or invalid state ID in WebAuthn response: $state_id");
        return $self->p->sendError( $req, 'PE82', 400 );
    }

    my $signature_options = ( $state_data->{authentication_options} );

    my $validation_result = eval {
        $self->validateAssertion( $req, $req->userData, $signature_options,
            $credential_json );
    };
    if ($@) {
        $self->logger->error("Webauthn validation error for $user: $@");
        return $self->p->sendJSONresponse( $req, { result => 0 } );
    }

    if ( $validation_result->{success} == 1 ) {
        return $self->p->sendJSONresponse( $req, { result => 1 } );
    }
    else {
        return $self->p->sendJSONresponse( $req, { result => 0 } );
    }
}

sub _delete {
    my ( $self, $req, $user ) = @_;

    # Check if unregistration is allowed
    return $self->p->sendError( $req, 'notAuthorized', 200 )
      unless $self->conf->{webauthn2fUserCanRemoveKey};

    my $epoch = $req->param('epoch')
      or
      return $self->p->sendError( $req, '"epoch" parameter is missing', 400 );

    if ( $self->del2fDevice( $req, $req->userData, $self->type, $epoch ) ) {
        return $self->p->sendJSONresponse( $req, { result => 1 } );
    }
    else {
        return $self->p->sendError( $req, '2FDeviceNotFound', 400 );
    }
}

# Main method
sub run {
    my ( $self, $req, $action ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };

    return $self->p->sendError( $req,
        'No ' . $self->conf->{whatToTrace} . ' found in user data', 500 )
      unless $user;

    # Check if U2F key can be updated
    my $msg = $self->canUpdateSfa( $req, $action );
    return $self->p->sendError( $req, $msg, 400 ) if $msg;

    if ( $action eq 'registrationchallenge' ) {
        return $self->_registrationchallenge( $req, $user );
    }

    elsif ( $action eq 'registration' ) {
        return $self->_registration( $req, $user );
    }

    elsif ( $action eq 'verificationchallenge' ) {
        return $self->_verificationchallenge( $req, $user );
    }

    elsif ( $action eq 'verification' ) {
        return $self->_verification( $req, $user );
    }

    elsif ( $action eq 'delete' ) {
        return $self->_delete( $req, $user );
    }

    else {
        $self->logger->error("Unknown WebAuthn action -> $action");
        return $self->p->sendError( $req, 'unknownAction', 400 );
    }

}

1;
