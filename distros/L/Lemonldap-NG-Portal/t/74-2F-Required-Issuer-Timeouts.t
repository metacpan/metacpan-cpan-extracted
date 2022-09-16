use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';
my $maintests = 19;

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }
    require Lemonldap::NG::Common::TOTP;

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
            '/2fregisters/totp/getkey', IO::String->new(''),
            cookie => $pdata,
            length => 0,
        ),
        'Get new key'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    my ( $key, $token );
    ok( $key   = $res->{secret}, 'Found secret' );
    ok( $token = $res->{token},  'Found token' );
    $key = Convert::Base32::decode_base32($key);

    # Wait for regular form timeout to expire
    Time::Fake->offset("+5m");

    # Post code
    my $code;
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    ok( $code =~ /^\d{6}$/, 'Code contains 6 digits' );
    my $s = "code=$code&token=$token";
    ok(
        $res = $client->_post(
            '/2fregisters/totp/verify',
            IO::String->new($s),
            length => length($s),
            cookie => $pdata,
        ),
        'Post code'
    );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{result} == 1, 'Key is registered' );

    # Try to sign-in
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            cookie => $pdata,
            accept => 'text/html',
        ),
        'Auth query'
    );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/totp2fcheck', 'token' );

    # Test Login timeout
    Time::Fake->offset("+10m");

    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    $query =~ s/code=/code=$code/;

    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
            length => length($query),
            cookie => $pdata,
            accept => 'text/html',
        ),
        'Post code'
    );
    my $id = expectCookie($res);
    $pdata = expectCookie( $res, 'lemonldappdata' );
    expectRedirection( $res, qr'http://auth.example.com/cas' );

    # Follow redirection to TOTP form
    ok(
        $res = $client->_get(
            '/cas',
            cookie => "lemonldap=$id; lemonldappdata=$pdata",
            accept => 'text/html',
        ),
        'Follow redirection to issuer'
    );
    expectRedirection( $res, qr#^http://cas.example.com/\?(ticket.*)# );
}
count($maintests);

clean_sessions();

done_testing( count() );

