use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';
my $maintests = 20;

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }
    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel               => 'error',
                loginHistoryEnabled    => 0,
                useSafeJail            => 1,
                totp2fSelfRegistration => 1,
                totp2fActivation       => 1,
                requireToken           => 1,
                formTimeout            => 120,
                loginHistoryEnabled    => 0,
                authentication         => 'Combination',
                userDB                 => 'Same',
                combination            => '[ssl, Dm1] or [Dm2]',
                combModules            => {
                    Dm1 => {
                        for  => 0,
                        type => 'Demo',
                    },
                    Dm2 => {
                        for  => 0,
                        type => 'Demo',
                    },
                    ssl => {
                        for  => 1,
                        type => 'SSL',
                    }
                },
            }
        }
    );
    my $res;

    ## Try to authenticate
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'token' );

    $query =~ s/user=/user=dwho/;
    $query =~ s/password=/password=dwho/;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Auth query'
    );
    count(1);
    my $id = expectCookie($res);
    expectRedirection( $res, 'http://auth.example.com/' );

    # TOTP form
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );

    # JS query
    ok(
        $res = $client->_post(
            '/2fregisters/totp/getkey', IO::String->new(''),
            cookie => "lemonldap=$id",
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
            cookie => "lemonldap=$id",
        ),
        'Post code'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{result} == 1, 'Key is registered' );
    $client->logout($id);

    # Try to sign-in with bad password
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'token' );

    $query =~ s/user=/user=dwho/;
    $query =~ s/password=/password=badpasswd/;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Auth query with bad password'
    );

    # Try to sign-in
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'token' );

    $query =~ s/user=/user=dwho/;
    $query =~ s/password=/password=dwho/;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Auth query'
    );

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/totp2fcheck', 'token' );
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    $query =~ s/code=/code=$code/;

    # Skip ahead in time until the form token has expired
    Time::Fake->offset("+5m");

    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    ok( $res->[2]->[0] =~ /<span trmsg="82"><\/span>/, 'Token expired' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'token' );
}
count($maintests);

clean_sessions();

done_testing( count() );

