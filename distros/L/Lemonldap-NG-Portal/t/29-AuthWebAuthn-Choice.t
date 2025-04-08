use warnings;
use Test::More;
use IO::String;
use URI;
use JSON;
use Lemonldap::NG::Portal::Main::Constants ':all';
use strict;

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

    my $webauthn_tester = Authen::WebAuthn::Test->new(
        origin        => "http://auth.example.com",
        rp_id         => "auth.example.com",
        credential_id => $credential_id_1,
        aaguid        => "00000000-0000-0000-0000-000000000000",
        key           => $ecdsa_key,
        sign_count    => 6,
    );
    my $res;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                authentication      => 'Choice',
                restSessionServer   => 1,
                requireToken        => 1,
                userDB              => 'Same',
                'authChoiceModules' => {
                    '1_WebAuthn' => 'WebAuthn;Demo;Null;;;{}',
                    '2_Demo'     => 'Demo;Demo;Null;;;{}'
                },
            }
        }
    );

    ok(
        $res = $client->_get(
            '/', accept => 'text/html'
        ),
        'Try to login'
    );

    expectPortalError( $res, 9, "Prompted to authenticate" );

    my $info = {
        '_2fDevices' => to_json( [ {
                    '_credentialId'        => 'bFpZbHRQOU10b1JOdVhLOGY4dFdm',
                    '_credentialPublicKey' =>
'pQECAyYgASFYIM_oQXEUzjPwEhM4gWmIbCuOXc4Ja8jPDKxbQaZckal7Ilgg_9a693_nkf7flk1S9AV2tjrtJPF6kg8TCGbFKoeD9Wc',
                    '_signCount' => 5,
                    'epoch'      => '1704384566',
                    'name'       => 'MyFirstDevice',
                    'type'       => 'WebAuthn'
                },
            ]
        ),
        '_webAuthnUserHandle' => "xxx",
        '_session_id'         => 'cb3c92b07fb624c9975186b57c627ae0',
        '_session_kind'       => 'Persistent',
        '_session_uid'        => 'dwho',
        '_updateTime'         => '20240102142212',
        '_utime'              => '1704201732'
    };
    $client->p->getPersistentSession( "dwho", $info );

    expectXpath( $res,
            '//script[starts-with(@src,"/static/common/js/'
          . 'webauthn-json.browser-global.min.js?v=")]' );
    expectXpath( $res,
            '//script[starts-with(@src,"/static/common/js/'
          . 'webauthncheck.min.js?v=")]' );
    my $js_vars   = getJsVars($res);
    my $request   = $js_vars->{request};
    my $challenge = $request->{challenge};

    ok( $challenge, "Found challenge" );
    is( $js_vars->{webauthn_autostart}, "0", "WebAuthn is set to auto start" );

    my ( $host, $url, $query ) =
      expectForm( $res, "#", undef, 'token', 'credential' );

    my $credential = $webauthn_tester->get_assertion_response( {
            request => $request,
        },
        { response => { userHandle => "xxx" } }
    );

    $credential = $webauthn_tester->encode_credential($credential);

    my $urlencoded_credential = buildForm( {
            credential => $credential
        }
    );

    $query =~ s/credential=/$urlencoded_credential/;
    $query =~ s/lmAuth=\w*/lmAuth=1_WebAuthn/;

    ok(
        $res = $client->_post(
            "/",
            IO::String->new($query),
            length => length($query),
        ),
        'Auth query'
    );

    my $id = expectCookie($res);
    expectSessionAttributes( $client, $id, uid => "dwho", _auth => "WebAuthn" );

}

done_testing();
