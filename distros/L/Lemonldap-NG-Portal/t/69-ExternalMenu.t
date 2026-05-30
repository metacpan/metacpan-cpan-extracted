use warnings;
use Test::More;
use strict;
use IO::String;
use MIME::Base64;

require 't/test-lib.pm';

my ( $res, $id );

# Test 1: ExternalMenu with variable interpolation
# -------------------------------------------------
my $client = LLNG::Manager::Test->new( {
        ini => {
            portal         => 'http://auth.example.com/',
            authentication => 'Demo',
            userDB         => 'Same',
            externalMenu   =>
              'https://apps.example.com/home?user=$uid&mail=$mail',
            totp2fActivation       => 'has2f("TOTP")',
            totp2fSelfRegistration => 1,
        }
    }
);

subtest 'urldc parameter takes priority over externalMenu', sub {
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
            query  => 'url=' . encode_base64( 'http://test1.example.com/', '' ),
        ),
        'Auth query with url parameter'
    );

    expectCookie($res);
    expectRedirection( $res, 'http://test1.example.com/' );
};

subtest 'Normal authentication redirects to external menu', sub {
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );
    expectRedirection( $res,
        'https://apps.example.com/home?user=dwho&mail=dwho%40badwolf.org' );

    $id = expectCookie($res);
};

subtest 'Authenticated users are redirected to external menu', sub {
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Access portal as authenticated user'
    );
    expectRedirection( $res,
        'https://apps.example.com/home?user=dwho&mail=dwho%40badwolf.org' );
};

subtest 'Plugins with API are not affected', sub {
    my ( $code, $s );
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );

    ok(
        $res = $client->_post(
            '/2fregisters/totp/getkey',
            IO::String->new(''),
            cookie => "lemonldap=$id",
            length => 0,
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Get new key'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    my ( $key, $token );
    ok( $key   = $res->{secret}, 'Found secret' ) or print STDERR Dumper($res);
    ok( $token = $res->{token},  'Found token' )  or print STDERR Dumper($res);
    ok( $res->{user} eq 'dwho', 'Found user' )
      or print STDERR Dumper($res);
    $key = Convert::Base32::decode_base32($key);

    # Post code
    ok( $code = getTotp($key), 'Code' );
    ok( $code =~ /^\d{6}$/,    'Code contains 6 digits' );
    $s = "code=$code&token=$token&TOTPName=my-T OTP";
    ok(
        $res = $client->_post(
            '/2fregisters/totp/verify',
            IO::String->new($s),
            length => length($s),
            cookie => "lemonldap=$id",
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Post code'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{result} == 1, 'TOTP is registered' );

    $client->logout($id);

    # Sign in works
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/totp2fcheck', 'token' );
    ok( $code = getTotp($key), 'Code' );
    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
            length => length($query),
        ),
        'Post code'
    );
    $id = expectCookie($res);
};

clean_sessions();
done_testing();
