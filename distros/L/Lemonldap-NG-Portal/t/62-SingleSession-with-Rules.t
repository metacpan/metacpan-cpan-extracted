use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            authentication => 'Demo',
            userDB         => 'Same',
            singleSession  => '$uid eq "dwho"',
            singleIP       => '$uid eq "rtyler"',
            singleUserByIP => '$env->{REMOTE_ADDR} eq "127.0.0.99"',
        }
    }
);

sub loginUser {
    my ( $client, $user, $ip ) = @_;
    my $query = "user=$user&password=$user";
    ok(
        my $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            ip     => $ip,
        ),
        'Auth query'
    );
    count(1);
    expectOK($res);
    return $res;
}

sub testReq {
    my ( $client, $id, $msg ) = @_;
    my $res;
    ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ), $msg );
    count(1);
    return $res;
}

my $dwho_1 = expectCookie( loginUser( $client, "dwho", "127.0.0.1" ) );
my $dwho_2 = expectCookie( loginUser( $client, "dwho", "127.0.0.1" ) );

# dwho is able to login
expectOK( testReq( $client, $dwho_2 ) );

# dwho can only have one session
expectReject( testReq( $client, $dwho_1 ) );

my $rtyler_1 = expectCookie( loginUser( $client, "rtyler", "127.0.0.1" ) );
my $rtyler_2 = expectCookie( loginUser( $client, "rtyler", "127.0.0.99" ) );
my $rtyler_3 = expectCookie( loginUser( $client, "rtyler", "127.0.0.99" ) );

# rtyler was able to login
expectOK( testReq( $client, $rtyler_3 ) );

# rtyler can have multiple sessions
expectOK( testReq( $client, $rtyler_2 ) );

# rtyler can only have sessions on her new IP'
expectReject( testReq( $client, $rtyler_1 ) );

my $msmith_1 = expectCookie( loginUser( $client, "msmith", "127.0.0.99" ) );
my $msmith_2 = expectCookie( loginUser( $client, "msmith", "127.0.0.1" ) );

# msmith was able to login
expectOK( testReq( $client, $msmith_2 ) );

# msmith was able to open multiple sessions
expectOK( testReq( $client, $msmith_1 ) );

# multiple users not allowed on special IP
expectReject( testReq( $client, $rtyler_3 ) );

# multiple users allowed on other IPs
expectOK( testReq( $client, $dwho_2 ) );

clean_sessions();

done_testing( count() );
