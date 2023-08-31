use warnings;
use Test::More;
use strict;
use IO::String;
use MIME::Base64;
use URI;
use URI::QueryParam;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                 => 'error',
            captcha_register_enabled => 1,
            customPlugins            => 't::SendHtmlPlugin',
            portal                   => 'https://auth.example.com/',
            registerDB               => "Demo",
        }
    }
);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
expectOK($res);
my $id = expectCookie($res);

ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get menu'
);

like(
    $res->[2]->[0],
    qr,Connected as</span> CUSTOM,,
    "Found customized template param from sendHtml"
);
is( $res->[0], 299, "Found customized response code" );

ok(
    $res = $client->_get(
        '/myhook',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get menu'
);

like( $res->[2]->[0], qr;trspan="oidcConsent,";, "Template was changed" );

ok(
    $res = $client->_get(
        '/register', accept => 'text/html'
    ),
    'Get menu'
);

like(
    $res->[2]->[0],
    qr,img id="captcha" src="xxxreplacedxxx",,
    "Found customized captcha from loadTemplate"
);

clean_sessions();

done_testing();
