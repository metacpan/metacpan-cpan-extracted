use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';
require Lemonldap::NG::Common::TOTP;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel             => 'error',
            totp2fActivation     => "\$targetAuthnLevel <= 10",
            password2fActivation => "\$targetAuthnLevel <= 5",
            authentication       => 'Choice',
            userDB               => 'Same',
            authChoiceModules    => {
                '1_Demo' => 'Demo;Demo;Null;;$targetAuthnLevel<=10',
                '2_Demo' => 'Demo;Demo;Null;;$targetAuthnLevel<=5',
            },

            vhostOptions => {
                "test1.example.com" => {
                    vhostAuthnLevel => 5
                },
                "test2.example.com" => {
                    vhostAuthnLevel => 10
                }
            }

        }
    }
);
my $res;
my $id;
my $key;
my $keySecret;
my $token;
my $code;

subtest "Check test1 offer both Auth choices and both 2FA choices" => sub {

    ok(
        $res = $client->_get(
            "/",
            query  => { url => encodeUrl("http://test1.example.com") },
            accept => "text/html"
        ),
        "Get login form"
    );
    my @forms = map { $_->getAttribute("value") }
      expectXpath( $res, '//input[@name="lmAuth"]' )->get_nodelist();
    is_deeply( [@forms], [qw/1_Demo 2_Demo/], "Two choices offered" );

    ok(
        $res = $client->_post(
            '/',
            {
                user     => "dwho",
                password => "dwho",
                lmAuth   => "1_Demo",
                url      => encodeUrl("http://test1.example.com"),
            }
        ),
        'Auth query'
    );
    expectXpath(
        $res,
        '//button[@name="sf" and @value="totp"]',
        "Found TOTP button"
    );
    expectXpath(
        $res,
        '//button[@name="sf" and @value="password"]',
        "Found password button"
    );
};

subtest "Check test2 vhost asks only TOTP" => sub {

    ok(
        $res = $client->_get(
            "/",
            query  => { url => encodeUrl("http://test2.example.com") },
            accept => "text/html"
        ),
        "Get login form"
    );
    my @forms = map { $_->getAttribute("value") }
      expectXpath( $res, '//input[@name="lmAuth"]' )->get_nodelist();
    is_deeply( [@forms], [qw/1_Demo/], "One choice offered" );

    ok(
        $res = $client->_post(
            '/',
            {
                user     => "dwho",
                password => "dwho",
                lmAuth   => "1_Demo",
                url      => encodeUrl("http://test2.example.com"),
            }
        ),
        'Auth query'
    );
    expectXpath( $res, '//span[@trspan="enterTotpCode"]', "Found TOTP prompt" );
};

clean_sessions();
done_testing();
