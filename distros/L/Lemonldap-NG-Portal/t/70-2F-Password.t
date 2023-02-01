use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                   => 'error',
            password2fSelfRegistration => 1,
            password2fActivation       => 1,
            password2fUserCanRemoveKey => 1,
            password2fAuthnLevel       => 5,
            authentication             => 'Demo',
            userDB                     => 'Same',
            restSessionServer          => 1,
        }
    }
);
my $res;

subtest 'Register Password 2FA' => sub {

    # Try to authenticate
    # -------------------
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password' );

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
    my $id = expectCookie($res);
    expectRedirection( $res, 'http://auth.example.com/' );

    # Password form
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    expectRedirection( $res, qr#/2fregisters/password$# );
    ok(
        $res = $client->_get(
            '/2fregisters/password',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /password2fregistration\.(?:min\.)?js/,
        'Found password js' );

    my $s = "password=somethingyouknow&passwordverify=wrong";
    ok(
        $res = expectJSON(
            $client->_post(
                '/2fregisters/password/verify',
                IO::String->new($s),
                length => length($s),
                cookie => "lemonldap=$id",
            )
        ),
        'Post registration (mismatched)'
    );
    is( $res->{error}, 'PE34' );

    my $s = "password=&passwordverify=";
    ok(
        $res = expectJSON(
            $client->_post(
                '/2fregisters/password/verify',
                IO::String->new($s),
                length => length($s),
                cookie => "lemonldap=$id",
            )
        ),
        'Post registration (mismatched)'
    );
    is( $res->{error}, 'missingPassword' );

    my $s = "password=somethingyouknow&passwordverify=somethingyouknow";
    ok(
        $res = expectJSON(
            $client->_post(
                '/2fregisters/password/verify',
                IO::String->new($s),
                length => length($s),
                cookie => "lemonldap=$id",
            )
        ),
        'Post registration (mismatched)'
    );
    ok( $res->{result} == 1, 'Key is registered' );
    $client->logout($id);
};

subtest 'Try to login with invalid 2FA password' => sub {
    my $res;
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password' );

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
    ( $host, $url, $query ) = expectForm( $res, undef, '/password2fcheck' );

    $query =~ s/password=/password=wrongpass/;
    ok(
        $res = $client->_post(
            '/password2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    expectPortalError( $res, 5 );
};

subtest 'Try to login with valid 2FA password' => sub {
    my $res;
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password' );

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
    ( $host, $url, $query ) = expectForm( $res, undef, '/password2fcheck' );

    $query =~ s/password=/password=somethingyouknow/;
    ok(
        $res = $client->_post(
            '/password2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    my $id   = expectCookie($res);
    my $attr = expectSessionAttributes(
        $client, $id,
        _auth               => "Demo",
        _2f                 => "password",
        uid                 => "dwho",
        authenticationLevel => 5,
    );
    $client->logout($id);
};

clean_sessions();

done_testing();

