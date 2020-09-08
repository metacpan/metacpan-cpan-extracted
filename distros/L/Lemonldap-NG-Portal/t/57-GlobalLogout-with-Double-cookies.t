use Test::More;
use strict;
use IO::String;
use Data::Dumper;
use JSON;
use Lemonldap::NG::Portal::Main::Constants 'PE_TOKENEXPIRED';

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel             => 'error',
            authentication       => 'Demo',
            userDB               => 'Same',
            loginHistoryEnabled  => 0,
            bruteForceProtection => 0,
            requireToken         => 0,
            securedCookie        => 2,
            restSessionServer    => 1,
            globalLogoutRule     => 1,
        }
    }
);

## First successful connection for 'dwho'
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '1st "dwho" Auth query'
);
count(1);
expectCookie($res);
my $id = expectCookie( $res, 'lemonldaphttp' );
expectRedirection( $res, 'http://auth.example.com/' );

## Second successful connection for "dwho"
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '2nd "dwho" Auth query'
);
count(1);
expectCookie($res);
expectCookie( $res, 'lemonldaphttp' );
expectRedirection( $res, 'http://auth.example.com/' );

## Third successful connection for 'dwho'
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '3rd "dwho" Auth query'
);
count(1);
expectCookie($res);
expectCookie( $res, 'lemonldaphttp' );
expectRedirection( $res, 'http://auth.example.com/' );

## Logout request for 'dwho'
ok(
    $res = $client->_get(
        '/',
        query  => 'logout',
        cookie => "lemonldaphttp=$id",
        accept => 'text/html'
    ),
    'Logout request for "dwho"'
);
count(1);

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/globallogout?all=1', 'token' );
ok( $res->[2]->[0] =~ m%<span trspan="globalLogout">%,
    'Found trspan="globalLogout"' )
  or explain( $res->[2]->[0], 'trspan="globalLogout"' );
my @c = ( $res->[2]->[0] =~ m%<td scope="row">127.0.0.1</td>%gs );
my @d = ( $res->[2]->[0] =~ m%<th scope="col">%gs );
my @e = ( $res->[2]->[0] =~ m%class="data-epoch">(\d{10})</td>%gs );

## Three entries found
ok( @c == 6, ' -> Six entries found' )
  or explain( $res->[2]->[0], "Number of session(s) found = " . scalar @c );
ok( @d == 4, ' -> Four <th> found' )
  or explain( $res->[2]->[0], "Number of <th> found = " . scalar @d );
ok( @e == 9, ' -> Nine epoch found' )
  or explain( $res->[2]->[0], "Number of epoch found = " . scalar @e );
ok( time() - 5 <= $e[0] && $e[0] <= time() + 5, 'Right epoch found' )
  or print STDERR Dumper( $res->[2]->[0] ), time(), " / $1";
count(5);

## GlobalLogout request for 'dwho' current session
ok(
    $res = $client->_post(
        '/globallogout',
        IO::String->new($query),
        cookie => "lemonldaphttp=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST /globallogout?all=1'
);
ok( $res->[2]->[0] =~ m%<span trmsg="47"></span>%, 'Found PE_LOGOUT_OK' )
  or explain( $res->[2]->[0], "PE_LOGOUT_OK" );
my $nbr = count_sessions();
ok( $nbr == 5, "Five sessions left" )
  or explain("Number of session(s) found = $nbr\n");
count(3);

clean_sessions();

done_testing( count() );
