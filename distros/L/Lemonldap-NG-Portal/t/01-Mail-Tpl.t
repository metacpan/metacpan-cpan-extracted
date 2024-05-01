use warnings;
use Test::More;
use strict;

require 't/test-lib.pm';
require 't/smtp.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            portal          => 'https://auth.example.com/',
            customPlugins   => "t::TestMail",
            skinTemplateDir => 't/templates',
        }
    }
);

# Default skin
subtest "Default skin, default language" => sub {
    clear_mail();
    ok( $res = $client->_get('/testmail'), 'request ok' );

    like( mail(), qr/Your login code/ );
    unlike(
        mail(),
        qr,Content-Type: image/png; name="logo_llng_400px\.png",,
        "Logo not attached"
    );
};

subtest "Default skin, custom language" => sub {
    clear_mail();
    ok( $res = $client->_get( '/testmail', cookie => "llnglanguage=fr" ),
        'request ok' );

    like( mail(), qr/Votre code de connexion est/ );
    unlike(
        mail(),
        qr,Content-Type: image/png; name="logo_llng_400px\.png",,
        "Logo not attached"
    );
};

subtest "custom skin, default language" => sub {
    clear_mail();
    ok( $res = $client->_get( '/testmail', query => "skin=mailtplskin" ),
        'Request ok' );

    like( mail(), qr/Your 2FA code/ );
    like(
        mail(),
        qr,Content-Type: image/png; name="logo_llng_400px\.png",,
        "Logo attached"
    );
};

subtest "custom skin, custom language" => sub {
    clear_mail();
    ok(
        $res = $client->_get(
            '/testmail',
            query  => "skin=mailtplskin",
            cookie => "llnglanguage=fr"
        ),
        'Request ok'
    );

    like( mail(), qr/Votre code 2FA/ );
    like(
        mail(),
        qr,Content-Type: image/png; name="logo_llng_400px\.png",,
        "Logo attached"
    );
};

done_testing();
