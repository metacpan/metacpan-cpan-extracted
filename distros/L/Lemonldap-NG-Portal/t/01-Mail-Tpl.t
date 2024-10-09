use warnings;
use Test::More;
use Lemonldap::NG::Portal::Main::Request;
use strict;

require 't/test-lib.pm';
require 't/smtp.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            portal          => 'https://auth.example.com/',
            customPlugins   => "t::TestMail",
            skinTemplateDir => 't/templates',
            msg_xxx         => "Translated subject",
        }
    }
);

subtest "Skin and language resolution" => sub {

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

    subtest "custom skin, custom language (cookie)" => sub {
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

    subtest "custom skin, custom language (header)" => sub {
        clear_mail();
        ok(
            $res = $client->_get(
                '/testmail',
                query  => "skin=mailtplskin",
                custom => {
                    'HTTP_ACCEPT_LANGUAGE' => 'fr-FR;q=0.7,en;q=0.3',
                },
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
};

subtest "Test sendEmail method" => sub {

    my $smtp = $client->p->loadedModules->{"t::TestMail"};
    my $req  = Lemonldap::NG::Portal::Main::Request->new(
        { PATH_INFO => "", REQUEST_URI => "/" } );
    $req->sessionInfo( {} );
    $req->sessionInfo->{uid} = "dwho";

    subtest "Use templated body and subject" => sub {
        clear_mail();
        $smtp->sendEmail(
            $req,
            dest          => 'dwho@example.com',
            subject_trmsg => "xxx",
            body_template => "test_mail",
            params        => { custom => "aa" },
        );
        like( mail(), qr/custom=aa/, "Found variable in templated body" );
        like( mail(), qr/uid=dwho/,
            "Found session variable in templated body" );
        is( subject(),             "Translated subject", "Found subject" );
        is( envelope()->{to}->[0], 'dwho@example.com', "Correct destination" );
    };

    subtest "Use explicit body and subject" => sub {
        clear_mail();
        $smtp->sendEmail(
            $req,
            dest          => 'dwho@example.com',
            subject       => "hardcoded subject",
            subject_trmsg => "xxx",
            body          => 'hardcodedbody $custom $uid',
            body_template => "test_mail",
            params        => { custom => "aa" },
        );
        like(
            mail(),
            qr,hardcodedbody aa dwho,,
            "Found expected hardcoded body"
        );
        is( subject(), "hardcoded subject", "Expected hardcoded subject" );
        is( envelope()->{to}->[0], 'dwho@example.com', "Correct destination" );
    };

};

done_testing();
