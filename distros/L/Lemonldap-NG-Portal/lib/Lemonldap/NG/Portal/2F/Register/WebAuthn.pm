# Self WebAuthn registration
package Lemonldap::NG::Portal::2F::Register::WebAuthn;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants 'PE_OK';
use JSON qw(from_json to_json);
use MIME::Base64 qw(encode_base64url decode_base64url);
use Crypt::URandom;

our $VERSION = '2.21.0';

extends 'Lemonldap::NG::Portal::2F::Register::Base';
with 'Lemonldap::NG::Portal::Lib::WebAuthn';

# INITIALIZATION

has logo     => ( is => 'rw', default => 'webauthn.png' );
has prefix   => ( is => 'rw', default => 'webauthn' );
has template => ( is => 'ro', default => 'webauthn2fregister' );
has welcome  => ( is => 'ro', default => 'webauthn2fWelcome' );
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

use constant supportedActions => {
    registrationchallenge => "_registrationchallenge",
    registration          => "_registration",
    verificationchallenge => "_verificationchallenge",
    verification          => "_verification",
    delete                => "delete",
};

sub initDisplay {
    my ( $self, $req ) = @_;

    my $cacheTag = $self->p->cacheTag;
    $req->data->{customScript} .= <<"EOF";
<script type="text/javascript" src="$self->{p}->{staticPrefix}/common/js/webauthn-json.browser-global.min.js?v=$cacheTag"></script>
<script type="text/javascript" src="$self->{p}->{staticPrefix}/common/js/webauthnregistration.min.js?v=$cacheTag"></script>
EOF

}

# Split content of webauthn2fAttestationTrust into an array ref of PEM certificates
sub _build_trust_anchors {
    my ($self) = shift;
    my $pem_data = $self->conf->{webauthn2fAttestationTrust};
    if ($pem_data) {
        my @split_certs = $pem_data =~
          /(-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----)/sg;
        if ( @split_certs > 0 ) {
            return \@split_certs;
        }
    }
    return [];
}

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
    my ( $self, $req ) = @_;

    return $self->failResponse( $req, 'csrfError', 400 )
      unless $self->checkCsrf($req);

    my $user             = $req->userData->{ $self->conf->{whatToTrace} };
    my @alldevices       = $self->find2fDevicesByType( $req, $req->userData );
    my $challenge_base64 = encode_base64url( Crypt::URandom::urandom(32) );

    my $displayName      = $req->userData->{ $self->displayname_attr } || $user;
    my $userVerification = $self->conf->{webauthn2fUserVerification};
    my $residentKey      = $self->conf->{webauthn2fResidentKey};
    my $attestation      = $self->conf->{webauthn2fAttestation} || "none";
    my $request          = {
        rp => {
            name => $self->rpName,
            id   => $self->rp_id($req),
        },
        user => {
            name        => $user,
            id          => $self->getRegistrationUserHandle($req),
            displayName => $displayName,
        },
        challenge              => $challenge_base64,
        attestation            => $attestation,
        pubKeyCredParams       => [],
        authenticatorSelection => { (
                $userVerification ? ( userVerification => $userVerification )
                : ()
            ),
            (
                $residentKey ? ( residentKey => $residentKey )
                : ()
            )
        }
    };

    # Challenge is persisted on the server
    my $token = $self->ott->createToken( {
            registration_options => $request,
        }
    );

    $self->logger->debug(
        "WebAuthn registration parameters " . to_json($request) );
    return $self->successResponse( $req,
        { request => $request, state_id => $token } );
}

sub _registration {
    my ( $self, $req ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };

    return $self->failResponse( $req, 'csrfError', 400 )
      unless $self->checkCsrf($req);

    # Recover creation parameters, including challenge
    my $state_id = $req->param('state_id');
    unless ($state_id) {
        $self->logger->error(
            $self->prefix . "2f: could not find state ID in response" );
        return $self->failResponse( $req, 'webAuthnRegisterFailed', 400 );
    }
    my $state_data;
    unless ( $state_data = $self->ott->getToken($state_id) ) {
        $self->logger->error( $self->prefix
              . "2f: expired or invalid state ID in response: $state_id" );
        return $self->failResponse( $req, 'PE82', 400 );
    }
    my $registration_options = ( $state_data->{registration_options} );
    unless ($registration_options) {
        $self->logger->error( $self->prefix
              . '2f: registration options missing from state data' );
        return $self->failResponse( $req, 'webAuthnRegisterFailed', 400 );
    }

    # Data required for WebAuthn verification
    my $credential_json = $req->param('credential');
    $self->logger->debug(
        $self->prefix . "2f: get registered credential data $credential_json" );

    unless ($credential_json) {
        $self->logger->error(
            $self->prefix . '2f: missing credential parameter' );
        return $self->failResponse( $req, 'webAuthnRegisterFailed', 400 );
    }

    my $validation = eval {
        $self->validateCredential( $req, $registration_options,
            $credential_json );
    };
    if ($@) {
        $self->logger->error(
            $self->prefix . "2f: Credential validation error: $@" );
        return $self->failResponse( $req, "webAuthnRegisterFailed", 400 );
    }

    my $credential_id     = $validation->{credential_id};
    my $credential_pubkey = $validation->{credential_pubkey};
    my $signature_count   = $validation->{signature_count};
    my $aaguid            = $validation->{attestation_result}->{aaguid};
    $self->logger->debug(
            $self->prefix
          . "2f: registering new credential: \n"
          . join( "\n",
            "ID: $credential_id",
            "Public key: $credential_pubkey",
            "Signature count: $signature_count",
            ( $aaguid ? "AAGUID: $aaguid" : () ) )
    );

    return $self->failResponse( $req, 'webauthnAlreadyRegistered', 400 )
      if $self->find2fDevicesByKey( $req, $req->userData, $self->type,
        "_credentialId", $credential_id );

    my $keyName =
      $self->checkNameSfa( $req, $self->type, $req->param('keyName') );
    return $self->failResponse( $req, 'badName', 200 ) unless $keyName;

    my $is_resident = (
        $registration_options->{authenticatorSelection}->{residentKey}
          and
          ( $registration_options->{authenticatorSelection}->{residentKey} eq
            "required" )
    );

    my $serialized_transports =
      $self->_serializeTransportsFromJsonResponse($credential_json);
    my $res = $self->registerDevice(
        $req,
        $req->userData,
        {
            _credentialId        => $credential_id,
            _credentialPublicKey => $credential_pubkey,
            _signCount           => $signature_count,
            (
                $serialized_transports
                ? ( _transports => $serialized_transports )
                : ()
            ),
            ( $aaguid ? ( _aaguid => $aaguid ) : () ),
            type  => $self->type,
            name  => $keyName,
            epoch => time(),
            ( $is_resident ? ( resident => 1 ) : () ),
        }
    );

    if ( $res == PE_OK ) {
        return $self->successResponse( $req, { result => 1 } );
    }
    else {
        $self->logger->error( $self->prefix . '2f: unable to add device' );
        return $self->failResponse( $req, "PE$res" );
    }
}

sub _verificationchallenge {
    my ( $self, $req ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };

    return $self->failResponse( $req, 'csrfError', 400 )
      unless $self->checkCsrf($req);

    $self->logger->debug( $self->prefix . '2f: verification challenge req' );

    my $request = $self->generateChallenge( $req, $req->userData );

    unless ($request) {
        $self->logger->error( $self->prefix . '2f: no registered device' );
        return $self->failResponse( $req, 'webAuthnNoDevice', 500 );
    }

    # Request is persisted on the server
    my $token = $self->ott->createToken( {
            authentication_options => $request,
        }
    );

    $self->logger->debug(
        $self->prefix . "2f: authentication parameters: " . to_json($request) );
    return $self->successResponse( $req,
        { request => $request, state_id => $token } );
}

sub _verification {
    my ( $self, $req ) = @_;
    my $user = $req->userData->{ $self->conf->{whatToTrace} };

    return $self->failResponse( $req, 'csrfError', 400 )
      unless $self->checkCsrf($req);

    my $credential_json = $req->param('credential');

    unless ($credential_json) {
        $self->logger->error(
            $self->prefix . '2f: missing credential parameter' );
        return $self->failResponse( $req, 'webAuthnFailed', 400 );
    }

    my $state_id = $req->param('state_id');
    unless ($state_id) {
        $self->logger->error( $self->prefix
              . "2f: could not find state ID in response ($credential_json)" );
        return $self->failResponse( $req, 'webAuthnFailed', 400 );
    }

    # Recover challenge
    my $state_data;
    unless ( $state_data = $self->ott->getToken($state_id) ) {
        $self->logger->error( $self->prefix
              . "2f: expired or invalid state ID in response ($state_id)" );
        return $self->failResponse( $req, 'PE82', 400 );
    }

    my $signature_options = ( $state_data->{authentication_options} );
    my $validation_result = eval {
        $self->validateAssertion( $req, $req->userData, $signature_options,
            $credential_json );
    };
    if ($@) {
        $self->logger->error(
            $self->prefix . "2f: validation error for $user: $@" );
        return $self->successResponse( $req, { result => 0 } );
    }

    if ( $validation_result->{success} == 1 ) {
        return $self->successResponse( $req, { result => 1 } );
    }
    else {
        return $self->successResponse( $req, { result => 0 } );
    }
}

1;
