use Test::More;
use strict;
use IO::String;
use MIME::Base64 qw/encode_base64url decode_base64url/;
use JSON;

require 't/test-lib.pm';

SKIP: {
    eval "use Authen::WebAuthn::Test; use Authen::WebAuthn;";
    if ($@) {
        skip 'Authen::WebAuthn not found';
    }

    my $ecdsa_key = <<ENDKEY;
-----BEGIN EC PRIVATE KEY-----
MIIBUQIBAQQgWEGujn2kkOVckTIKhIJDSqH99bxydPGloXvbeaq9swiggeMwgeAC
AQEwLAYHKoZIzj0BAQIhAP////8AAAABAAAAAAAAAAAAAAAA////////////////
MEQEIP////8AAAABAAAAAAAAAAAAAAAA///////////////8BCBaxjXYqjqT57Pr
vVV2mIa8ZR0GsMxTsPY7zjw+J9JgSwRBBGsX0fLhLEJH+Lzm5WOkQPJ3A32BLesz
oPShOUXYmMKWT+NC4v4af5uO5+tKfA+eFivOM1drMV7Oy7ZAaDe/UfUCIQD/////
AAAAAP//////////vOb6racXnoTzucrC/GMlUQIBAaFEA0IABM/oQXEUzjPwEhM4
gWmIbCuOXc4Ja8jPDKxbQaZckal7/9a693/nkf7flk1S9AV2tjrtJPF6kg8TCGbF
KoeD9Wc=
-----END EC PRIVATE KEY-----
ENDKEY

    my $credential_id_1 = "lZYltP9MtoRNuXK8f8tWf";
    my $credential_id_2 = "d2ViYXV0aG5fdGVzdGVyXzI";

    my $webauthn_tester_1 = Authen::WebAuthn::Test->new(
        origin        => "http://auth.example.com",
        rp_id         => "auth.example.com",
        credential_id => $credential_id_1,
        aaguid        => "00000000-0000-0000-0000-000000000000",
        key           => $ecdsa_key,
        sign_count    => 5,
    );

    my $webauthn_tester_2 = Authen::WebAuthn::Test->new(
        origin        => "http://auth.example.com",
        rp_id         => "auth.example.com",
        credential_id => $credential_id_2,
        aaguid        => "00000000-0000-0000-0000-000000000000",
        key           => $ecdsa_key,
        sign_count    => 18,
    );

    #FIXME
    my $webauthn_tester = $webauthn_tester_1;

    my $res;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => 'error',
                useSafeJail                => 1,
                webauthn2fSelfRegistration => 1,
                webauthn2fActivation       => 1,
                webauthn2fUserCanRemoveKey => 1,
                webauthnDisplayNameAttr    => 'cn',
            }
        }
    );

    my $portal = $client->p;

    sub login_and_check_display {
        my ($client) = @_;
        my $res;

        ok(
            $res = $client->_post(
                '/', IO::String->new('user=dwho&password=dwho'),
                length => 23,
            ),
            'Create Session'
        );

        expectOK($res);
        my $id = expectCookie($res);

        # Display 2FA Manager
        ok(
            $res = $client->_get(
                '/2fregisters',
                cookie => "lemonldap=$id",
                accept => "test/html",
            ),
            'Show 2FA Manager'
        );

        expectRedirection( $res,
            'http://auth.example.com//2fregisters/webauthn' );

        # Display WebAuthn registration
        ok(
            $res = $client->_get(
                '/2fregisters/webauthn',
                cookie => "lemonldap=$id",
                accept => "test/html",
            ),
            'Show WebAuthn registration'
        );

        like(
            $res->[2]->[0],
            qr%<img src="/static/bootstrap/webauthn.png"%,
            "WebAuthn logo found"
        );
        like(
            $res->[2]->[0],
            qr%<div id="u2fPermission" trspan="u2fPermission"%,
            "Security help message found"
        );
        return $id;
    }

    sub register_new_device {
        my ( $client, $id, $webauthn_tester, $device_name, $expected_error ) =
          @_;
        my $res;

        ok(
            $res = $client->_post(
                '/2fregisters/webauthn/registrationchallenge',
                IO::String->new('{}'),
                cookie => "lemonldap=$id",
                length => 2,
            ),
            'Registration challenge'
        );

        my $reg_challenge = from_json $res->[2]->[0];

        is( $reg_challenge->{request}->{rp}->{name},
            "LemonLDAP::NG", "rp.name is set" );
        is( $reg_challenge->{request}->{user}->{name},
            "dwho", "user.name is set" );
        is( length( $reg_challenge->{request}->{user}->{id} ),
            86, "user.id is set" );
        is( $reg_challenge->{request}->{user}->{displayName},
            "Doctor Who", "user.displayName is set" );

        my $state_id  = $reg_challenge->{state_id};
        my $challenge = $reg_challenge->{request}->{challenge};

        ok( $state_id,  "State ID is set" );
        ok( $challenge, "Challenge is set" );

        my $credential_response =
          $webauthn_tester->get_credential_response($reg_challenge);
        my $registration_response = buildForm( {
                credential =>
                  $webauthn_tester->encode_credential($credential_response),
                state_id => $state_id,
                keyName  => $device_name,
            }
        );

        # Post registration
        ok(
            $res = $client->_post(
                '/2fregisters/webauthn/registration',
                IO::String->new($registration_response),
                cookie => "lemonldap=$id",
                length => length($registration_response),
            ),
            'Registration challenge'
        );

        my $reg_response = from_json $res->[2]->[0];
        if ($expected_error) {
            is( $reg_response->{result} // 0, 0, "Failed registration" );
            is( $reg_response->{error}, $expected_error,
                "Failed registration" );
            is( $res->[0], 400, "Expected failure http code" );
        }
        else {
            is( $reg_response->{result}, 1, "Successful registration" );
        }

        # return userHandle
        return $reg_challenge->{request}->{user}->{id};
    }

    sub verify_device {
        my ( $client, $id, $webauthn_tester, $expected_credentials ) = @_;
        my $res;

        # Get verification parameters
        ok(
            $res = $client->_post(
                '/2fregisters/webauthn/verificationchallenge',
                IO::String->new('{}'),
                cookie => "lemonldap=$id",
                length => 2,
            ),
            'Registration challenge'
        );

        my $verif_challenge = from_json $res->[2]->[0];

        is_deeply( $verif_challenge->{request}->{allowCredentials},
            $expected_credentials );

        my $state_id  = $verif_challenge->{state_id};
        my $challenge = $verif_challenge->{request}->{challenge};

        ok( $state_id,  "State ID is set" );
        ok( $challenge, "Challenge is set" );

        # Increment signature to avoid validation error
        $webauthn_tester->sign_count( $webauthn_tester->sign_count + 1 );
        my $credential_response =
          $webauthn_tester->get_assertion_response($verif_challenge);
        my $verification_response = buildForm( {
                state_id   => $state_id,
                credential =>
                  $webauthn_tester->encode_credential($credential_response),
            }
        );

        # Verify registration
        ok(
            $res = $client->_post(
                '/2fregisters/webauthn/verification',
                IO::String->new($verification_response),
                cookie => "lemonldap=$id",
                length => length($verification_response),
            ),
            'Registration challenge'
        );

        my $verif_response = from_json $res->[2]->[0];
        is( $verif_response->{result}, 1, "Successful verification" );
    }

    sub check_psession {
        my ( $portal, $user_handle ) = @_;

        # Inspect Psession content
        my $psession = $portal->getPersistentSession("dwho");

        # userHandle is stored
        is( $psession->{data}->{_webAuthnUserHandle},
            $user_handle, "User handle saved" );

        my $devices = from_json $psession->{data}->{_2fDevices};
        is( @{$devices}, 2, "2 devices found" );
        my $device1 = $devices->[0];
        my $device2 = $devices->[1];

        # Epoch will differ
        delete $device1->{epoch};
        delete $device2->{epoch};
        is_deeply(
            $device1,
            {
                '_credentialId'        => encode_base64url($credential_id_1),
                '_credentialPublicKey' =>
'pQECAyYgASFYIM_oQXEUzjPwEhM4gWmIbCuOXc4Ja8jPDKxbQaZckal7Ilgg_9a693_nkf7flk1S9AV2tjrtJPF6kg8TCGbFKoeD9Wc',
                '_signCount' => 5,
                'name'       => "MyFirstDevice",
                'type'       => 'WebAuthn'
            },
            "Registration contains expected data"
        );
        is_deeply(
            $device2,
            {
                '_credentialId'        => encode_base64url($credential_id_2),
                '_credentialPublicKey' =>
'pQECAyYgASFYIM_oQXEUzjPwEhM4gWmIbCuOXc4Ja8jPDKxbQaZckal7Ilgg_9a693_nkf7flk1S9AV2tjrtJPF6kg8TCGbFKoeD9Wc',
                '_signCount' => 18,
                'name'       => "MySecondDevice",
                'type'       => 'WebAuthn'
            },
            "Registration contains expected data"
        );
    }

    my $id = login_and_check_display($client);

    my $user_handle_1 =
      register_new_device( $client, $id, $webauthn_tester_1, "MyFirstDevice" );

    # Register same device again, fails because credential ID is already taken
    register_new_device( $client, $id, $webauthn_tester_1,
        "MyAlreadyRegisteredDevice", "webauthnAlreadyRegistered" );

    # Register a different device should succeed
    my $user_handle_2 =
      register_new_device( $client, $id, $webauthn_tester_2, "MySecondDevice" );

    # userHandle was kept from first registration
    is( $user_handle_2, $user_handle_1,
        "userHandle was kept from first registration" );

    check_psession( $portal, $user_handle_1 );

    verify_device(
        $client, $id,
        $webauthn_tester_1,
        [ {
                'id'   => encode_base64url($credential_id_1),
                'type' => 'public-key'
            },
            {
                'id'   => encode_base64url($credential_id_2),
                'type' => 'public-key'
            }
        ]
    );

}

# TODO delete
clean_sessions();

done_testing();
