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

    my $webauthn_tester = Authen::WebAuthn::Test->new(
        origin        => "http://auth.example.com",
        rp_id         => "auth.example.com",
        credential_id => "lZYltP9MtoRNuXK8f8tWf",
        aaguid        => "00000000-0000-0000-0000-000000000000",
        key           => $ecdsa_key,
        sign_count    => 5,
    );

    my $res;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => 'error',
                useSafeJail                => 1,
                webauthn2fSelfRegistration => 0,
                webauthn2fActivation       => 1,
                webauthn2fUserCanRemoveKey => 1,
            }
        }
    );

    my $portal = $client->p;
    $portal->getPersistentSession(
        "dwho",
        {
            _2fDevices => to_json [ {
                    "_credentialId"        => "bFpZbHRQOU10b1JOdVhLOGY4dFdm",
                    "_credentialPublicKey" =>
                      encode_base64url( $webauthn_tester->encode_cosekey ),
                    "_signCount" => "1",
                    "epoch"      => "1640015033",
                    "name"       => "MyFidoKey",
                    "type"       => "WebAuthn"
                },
            ],
        }
    );

    # Authenticate with good password
    # --------------------------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
        ),
        'Auth query'
    );

    expectOK($res);
    my ( $host, $url, $query ) =
      expectForm( $res, "", '/webauthn2fcheck', 'token', 'credential' );

    my ($json) = $res->[2]->[0] =~
      m#<script type="application/init">\s*(\{"request"[^<]*\})\s*</script>#ms;
    ok( $json, "Found request object in JS data" );
    $json = from_json($json);
    my $request   = $json->{request};
    my $challenge = $request->{challenge};
    ok( $challenge, "Found challenge" );

    is( $request->{extensions}->{appid},
        'http://auth.example.com', "Correct U2F AppID" );
    is( @{ $request->{allowCredentials} },
        1, "Found only one allowed credentials" );
    is(
        $request->{allowCredentials}->[0]->{id},
        "bFpZbHRQOU10b1JOdVhLOGY4dFdm",
        "Correct credential ID"
    );
    is( $request->{allowCredentials}->[0]->{type},
        "public-key", "Correct public key" );

    my $credential = $webauthn_tester->get_assertion_response( {
            request => $request,
        }
    );

    $credential = $webauthn_tester->encode_credential($credential);

    #diag $credential;

    my $urlencoded_credential = buildForm( {
            credential => $credential
        }
    );

    $query =~ s/credential=/$urlencoded_credential/;
    ok(
        $res = $client->_post(
            $url,
            IO::String->new($query),
            length => length($query),
        ),
        'Auth query'
    );

    my $id = expectCookie($res);

    # Test logout
    $client->logout($id);

}
clean_sessions();

done_testing();
