package Lemonldap::NG::Portal::Lib::WebAuthn;

use strict;
use Mouse::Role;
use MIME::Base64 qw(encode_base64url decode_base64url);
use JSON qw(decode_json from_json to_json);
use Digest::SHA qw(sha256);
use URI;
use Carp;
with 'Lemonldap::NG::Portal::Lib::2fDevices';
use Lemonldap::NG::Common::Util qw/display2F/;

our $VERSION = '2.19.0';

has trust_anchors => (
    is      => 'rw',
    lazy    => 1,
    isa     => "ArrayRef",
    builder => "_build_trust_anchors"
);

sub _build_trust_anchors {
    return [];
}

sub verifier {
    my ( $self, $req ) = @_;
    return Authen::WebAuthn->new(
        rp_id  => $self->rp_id($req),
        origin => $self->origin($req),
    );
}

sub rp_id {
    my ( $self, $req ) = @_;

    if ( $self->conf->{webauthnRpId} ) {
        return $self->conf->{webauthnRpId};
    }
    else {
        my $portal_uri = URI->new( $req->portal );
        if ( $portal_uri->can('host') ) {
            return $portal_uri->host;
        }
        else {
            return $portal_uri->authority;
        }
    }
}

sub origin {
    my ( $self, $req ) = @_;
    my $portal_uri = URI->new( $req->portal );
    return ( $portal_uri->scheme . "://" . $portal_uri->authority );
}

around 'init' => sub {
    my $orig = shift;
    my $self = shift;

    eval { require Authen::WebAuthn };
    if ($@) {
        $self->logger->error("Can't load WebAuthn library: $@");
        $self->error("Can't load WebAuthn library: $@");
        return 0;
    }

    return $orig->( $self, @_ );
};

sub getUserHandle {
    my ( $self, $req, $data ) = @_;
    return $data->{_webAuthnUserHandle};
}

sub setUserHandle {
    my ( $self, $req, $user_handle ) = @_;
    $self->p->updatePersistentSession( $req,
        { _webAuthnUserHandle => $user_handle } );
    return;
}

sub generateChallenge {
    my ( $self, $req, $data ) = @_;

    # Find webauthn devices for user
    my @webauthn_devices =
      $self->find2fDevicesByType( $req, $data, $self->type );
    return unless @webauthn_devices;

    my $challenge_base64 = encode_base64url( Crypt::URandom::urandom(32) );
    my $userVerification = $self->conf->{webauthn2fUserVerification};

    return {
        challenge        => $challenge_base64,
        rpId             => $self->rp_id($req),
        allowCredentials => [
            map { { type => "public-key", id => $_->{_credentialId}, } }
              @webauthn_devices
        ],
        ( $userVerification ? ( userVerification => $userVerification ) : () ),
        extensions => {
            appid => $self->origin($req),
        },
    };
}

sub validateCredential {
    my ( $self, $req, $registration_options, $credential_json ) = @_;
    my $credential             = from_json($credential_json);
    my $client_data_json_b64   = $credential->{response}->{clientDataJSON};
    my $attestation_object_b64 = $credential->{response}->{attestationObject};
    my $requested_uv =
      $registration_options->{authenticatorSelection}->{userVerification} || '';
    my $challenge_b64 = $registration_options->{challenge};
    my $token_binding_id_b64 =
      $req->headers->header('Sec-Provided-Token-Binding-ID')
      ? encode_base64url(
        $req->headers->header('Sec-Provided-Token-Binding-ID') )
      : '';

    # If Authen::WebAuthn is too old, we can't check attestation
    my $attestation = $registration_options->{attestation} || "none";
    if ( $attestation ne "none" and $Authen::WebAuthn::VERSION < 0.002 ) {
        croak(  "Authen::WebAuthn version is too old"
              . " ($Authen::WebAuthn::VERSION < 0.002),"
              . " cannot validate attestation" );
    }

    return $self->verifier($req)->validate_registration(
        challenge_b64          => $challenge_b64,
        requested_uv           => $requested_uv,
        client_data_json_b64   => $client_data_json_b64,
        attestation_object_b64 => $attestation_object_b64,
        token_binding_id_b64   => $token_binding_id_b64,
        trust_anchors          => $self->trust_anchors,
        (
            $attestation ne "none"
            ? ( allowed_attestation_types => ["Basic"] )
            : ()
        ),
    );
}

sub validateAssertion {
    my ( $self, $req, $data, $signature_options, $credential_json ) = @_;
    my $user = $data->{ $self->conf->{whatToTrace} };

    $self->logger->debug("Get asserted credential $credential_json");
    my $credential    = from_json($credential_json);
    my $credential_id = $credential->{id};
    croak("Empty credential id in credential response") unless $credential_id;

    # 5. If options.allowCredentials is not empty, verify that credential.id
    # identifies one of the public key credentials listed in
    # options.allowCredentials.
    my @allowed_credential_ids =
      map { $_->{id} } @{ $signature_options->{allowCredentials} };
    croak("Received credential ID $credential_id was not requested")
      if ( @allowed_credential_ids
        and not grep { $_ eq $credential_id } @allowed_credential_ids );

    # 6. Identify the user being authenticated and verify that this user is the
    # owner of the public key credential source credentialSource identified by
    # credential.id If the user was identified before the authentication
    # ceremony was initiated, e.g., via a username or cookie, verify that the
    # identified user is the owner of credentialSource.
    my @webauthn_devices =
      $self->find2fDevicesByType( $req, $data, $self->type );
    my @matching_credentials =
      grep { $_->{_credentialId} eq $credential_id } @webauthn_devices;

    croak("Received credential ID $credential_id does not belong to user")
      if ( @matching_credentials < 1 );
    croak("Found multiple credentials with ID $credential_id for user")
      if ( @matching_credentials > 1 );
    my $matching_credential = $matching_credentials[0];

    # If response.userHandle is present, let userHandle be its value.
    # Verify that userHandle also maps to the same user.
    if ( $credential->{response}->{userHandle} ) {
        my $user_handle         = $credential->{response}->{userHandle};
        my $current_user_handle = $self->getUserHandle( $req, $data );
        croak(
"Received user handle ($user_handle) does not match current user ($current_user_handle)"
        ) unless ( $user_handle eq $current_user_handle );
    }

    # TODO If the user was not identified before the authentication ceremony
    # was initiated, verify that response.userHandle is present, and that the
    # user identified by this value is the owner of credentialSource.
    # NOTE: irrelevant for now, take this into account when implementing
    # Auth::WebAuthn

    my $client_data_json_b64   = $credential->{response}->{clientDataJSON};
    my $authenticator_data_b64 = $credential->{response}->{authenticatorData};
    my $signature_b64          = $credential->{response}->{signature};
    my $extension_results      = $credential->{clientExtensionResults};
    my $requested_uv           = $signature_options->{userVerification} || "";

    my $token_binding_id_b64 =
      $req->headers->header('Sec-Provided-Token-Binding-ID')
      ? encode_base64url(
        $req->headers->header('Sec-Provided-Token-Binding-ID') )
      : '';

    my $validation_result = $self->verifier($req)->validate_assertion(
        challenge_b64          => $signature_options->{challenge},
        credential_pubkey_b64  => $matching_credential->{_credentialPublicKey},
        stored_sign_count      => $matching_credential->{_signCount},
        requested_uv           => $requested_uv,
        client_data_json_b64   => $client_data_json_b64,
        authenticator_data_b64 => $authenticator_data_b64,
        signature_b64          => $signature_b64,
        extension_results      => $extension_results,
        token_binding_id_b64   => $token_binding_id_b64,
    );

    if ( $validation_result->{success} == 1 ) {
        my $new_signature_count = $validation_result->{signature_count};

        $self->auditLog(
            $req,
            message => (
                    "User $user authenticated with 2F device: "
                  . display2F($matching_credential)
                  . " (signature count: $new_signature_count) "
            ),
            code            => "2FA_SUCCESS",
            user            => $user,
            type            => $self->prefix,
            device          => display2F($matching_credential),
            signature_count => $new_signature_count,
        );

        # Update storedSignCount to be the value of authData.signCount
        $self->update2fDevice( $req, $data, $self->type,
            "_credentialId", $credential_id, "_signCount",
            $new_signature_count );
    }

    return $validation_result;
}

sub decode_credential {
    my ( $self, $json ) = @_;
    my $credential = decode_json($json);

    # Decode ClientDataJSON
    if ( $credential->{response}->{clientDataJSON} ) {
        $credential->{response}->{clientDataJSON} = decode_json(
            decode_base64url( $credential->{response}->{clientDataJSON} ) );
    }

    # Decode attestation object
    if ( $credential->{response}->{attestationObject} ) {
        $credential->{response}->{attestationObject} =
          getAttestationObject( $credential->{response}->{attestationObject} );
    }

    # Decode authenticator data
    if ( $credential->{response}->{authenticatorData} ) {
        $credential->{response}->{authenticatorData} =
          getAuthData(
            decode_base64url( $credential->{response}->{authenticatorData} ) );
    }

    # Decode rawID
    if ( $credential->{rawId} ) {
        $credential->{rawId} = decode_base64url( $credential->{rawId} );
    }

    return $credential;
}

1;
