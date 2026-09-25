use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel               => 'error',
            totp2fSelfRegistration => 1,
            totp2fActivation       => 1,
            sfRequired             => 1,
            sfRegisterTimeout      => 600,
            sfLoginTimeout         => 600,
            tokenUseGlobalStorage  => 1,
            issuerDBCASActivation  => 1,
            issuersTimeout         => 1200,
        }
    }
);

my $key;
subtest "after sfRegisterTimeout, report errors correctly" => sub {
    my $res;

    # Post login form
    # ---------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    expectRedirection( $res, qr'http://auth.example.com/+2fregisters/?' );
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Follow redirection to TOTP form
    ok( $res = $client->_get( '/2fregisters', cookie => $pdata ),
        'Follow redirection to /2fregisters' );
    ok( $res->[2]->[0] =~ m#/2fregisters/totp#, 'Found TOTP link' );

    # TOTP form
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => $pdata,
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );

    # JS query
    ok(
        $res = $client->_post(
            '/2fregisters/totp/getkey',
            IO::String->new(''),
            length => 0,
            cookie => $pdata,
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Get new key'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    my ($token);
    ok( $key   = $res->{secret}, 'Found secret' );
    ok( $token = $res->{token},  'Found token' );
    $key = Convert::Base32::decode_base32($key);

    # Wait for regular form timeout to expire
    Time::Fake->offset("+15m");

    # Post code, errors reported in JSON
    my $code;
    ok( $code = getTotp($key), 'Code' );
    ok( $code =~ /^\d{6}$/,    'Code contains 6 digits' );
    my $s = "code=$code&token=$token";
    ok(
        $res = $client->_post(
            '/2fregisters/totp/verify',
            IO::String->new($s),
            length => length($s),
            cookie => $pdata,
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Post code'
    );
    expectReject( $res, 500, "PE82" );
    ok(
        !expectCookie( $res, 'lemonldappdata' ),
        "invalid sfRegToken is cleared"
    );

    # Refresh page redirects to portal
    ok(
        $res = $client->_get(
            '/2fregisters/totp', accept => 'text/html',
        ),
        'Form registration'
    );
    expectRedirection( $res, qr'http://auth.example.com' );
};

subtest "sfRegisterTimeout allows registering after a long pause" => sub {
    Time::Fake->reset;
    my $res;

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_get(
            '/cas/login',
            query => buildForm( {
                    service => "http://cas.example.com/",
                }
            ),
            accept => 'text/html',
            length => 23
        ),
        'Auth query'
    );
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Post login form
    # ---------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            cookie => $pdata,
            length => 23
        ),
        'Auth query'
    );
    expectRedirection( $res, qr'http://auth.example.com/+2fregisters/?' );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Follow redirection to TOTP form
    ok( $res = $client->_get( '/2fregisters', cookie => $pdata ),
        'Follow redirection to /2fregisters' );
    ok( $res->[2]->[0] =~ m#/2fregisters/totp#, 'Found TOTP link' );

    # TOTP form
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => $pdata,
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );

    # JS query
    ok(
        $res = $client->_post(
            '/2fregisters/totp/getkey',
            IO::String->new(''),
            cookie => $pdata,
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
    my ($token);
    ok( $key   = $res->{secret}, 'Found secret' );
    ok( $token = $res->{token},  'Found token' );
    $key = Convert::Base32::decode_base32($key);

    # Wait for regular form timeout to expire
    Time::Fake->offset("+5m");

    # Post code
    my $code;
    ok( $code = getTotp($key), 'Code' );
    ok( $code =~ /^\d{6}$/,    'Code contains 6 digits' );
    my $s = "code=$code&token=$token";
    ok(
        $res = $client->_post(
            '/2fregisters/totp/verify',
            IO::String->new($s),
            length => length($s),
            cookie => $pdata,
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Post code'
    );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{result} == 1, 'Key is registered' );
};

subtest "sfLoginTimeout allows logging in after a long pause" => sub {
    my ( $res, $pdata, $code );

    # Try to sign-in
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

    # Test Login timeout
    Time::Fake->offset("+10m");

    ok( $code = getTotp($key), 'Code' );
    $query =~ s/code=/code=$code/;

    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    my $id = expectCookie($res);
    expectRedirection( $res, qr'http://auth.example.com/' );
};

clean_sessions();

done_testing();

