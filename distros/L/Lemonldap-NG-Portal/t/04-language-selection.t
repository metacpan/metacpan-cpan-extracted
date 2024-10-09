use warnings;
use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my ( $client, $res, $id );

$client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            restSessionServer => 1,
            useSafeJail       => 1,
            sameSite          => 'Strict',
            languages         => "de, en, fr, es",
        },
    }
);

subtest "test _language session variable, default language" => sub {
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query without language cookie'
    );
    expectOK($res);
    $id = expectCookie($res);

    ok( getSession($id)->data->{_language} eq 'en',
        'Default value for _language' );

    $client->logout($id);
};

subtest "test _language session variable, with cookie" => sub {
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            cookie => "llnglanguage=fr",
            length => 23
        ),
        'Auth query with language cookie'
    );
    expectOK($res);
    $id = expectCookie($res);
    my $rawCookie = getHeader( $res, 'Set-Cookie' );
    ok( $rawCookie =~ /;\s*SameSite=Strict/, 'Found SameSite=Strict (conf)' )
      or explain( $rawCookie, 'SameSite value must be "Strict"' );
    ok( getSession($id)->data->{_language} eq 'fr',
        'Correct value for _language' );

    $client->logout($id);
};

sub getDetectedLangage {
    my ( $client, $cookielang, $acceptheader ) = @_;
    ok(
        $res = $client->_get(
            "/",
            accept => "text/html",
            ( $cookielang ? ( cookie => "llnglanguage=$cookielang" ) : () ),
            host   => "auth.example.com",
            custom => { HTTP_ACCEPT_LANGUAGE => ( $acceptheader || '' ) },
        )
    );
    my $language = getJsVars($res)->{language};
    ok( $language, "Language was found in response" );
    return $language;
}
subtest "test language resolution by portal" => sub {

    # cookie, accept-language header, result, comment
    my @tests = ( [
            undef, undef,
            "de",  "Default language is the first one mentionned in ini file"
        ],
        [ "fr", undef, "fr", "Known language from cookie is selected" ],
        [
            "xz", undef,
            "de", "Unknown language from cookie falls back to ini file"
        ],
        [ "en", "fr", "en", "Cookie has priority over Accept-Language" ],
        [
            undef, "fr", "fr",
            "Known language from Accept-Language is selected"
        ],
        [
            undef, "fr-FR",
            "fr",  "Known language from Accept-Language is selected"
        ],
        [
            undef, "xy-de,fr-FR",
            "fr",  "First known language from Accept-Language is selected"
        ],
        [
            undef, "xy-de,zz",
            "de",  "Unknown Accept-Language values fall back to ini"
        ],
        [
            undef, "fr-FR;q=0.4, en;q=0.9,;invalid",
            "en",  "Priority in Accept-Language is obeyed"
        ],
    );

    for my $params (@tests) {
        my ( $cookielang, $acceptheader, $result, $comment ) = @$params;
        is( getDetectedLangage( $client, $cookielang, $acceptheader ),
            $result, $comment );
    }
};

clean_sessions();

done_testing();
