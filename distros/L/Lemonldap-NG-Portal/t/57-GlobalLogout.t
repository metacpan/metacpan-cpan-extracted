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
            logLevel                => 'error',
            authentication          => 'Demo',
            userDB                  => 'Same',
            loginHistoryEnabled     => 0,
            bruteForceProtection    => 0,
            requireToken            => 0,
            restSessionServer       => 1,
            globalLogoutRule        => '$uid eq "dwho"',
            globalLogoutCustomParam => 'zeAUTHMODE_authmode'
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
my $idd = expectCookie($res);
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
expectRedirection( $res, 'http://auth.example.com/' );

## First successful connection for 'rtyler'
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=rtyler&password=rtyler'),
        length => 27,
        accept => 'text/html',
    ),
    '1st "rtyler" Auth query'
);
count(1);
my @idr;
$idr[0] = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

## 2nd successful connection for 'rtyler'
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=rtyler&password=rtyler'),
        length => 27,
        accept => 'text/html',
    ),
    '2nd "rtyler" Auth query'
);
count(1);
$idr[1] = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

my $nbr = count_sessions();
ok( $nbr == 5, "Five sessions found" )
  or explain("Number of session(s) found = $nbr");
count(1);

## Logout request for 'rtyler'
ok(
    $res = $client->_get(
        '/',
        query  => 'logout',
        cookie => "lemonldap=$idr[0]",
        accept => 'text/html'
    ),
    'Logout request for "rtyler"'
);
count(1);

ok( $res->[2]->[0] =~ m%<span trmsg="47"></span>%, 'Found PE_LOGOUT_OK' )
  or explain( $res->[2]->[0], "PE_LOGOUT_OK" );
count(1);
$client->logout( $idr[1] );

$nbr = count_sessions();
ok( $nbr == 3, "Three sessions found" )
  or explain("Number of session(s) found = $nbr");
count(1);

## Logout request for 'dwho'
ok(
    $res = $client->_get(
        '/',
        query  => 'logout',
        cookie => "lemonldap=$idd",
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
ok( $res->[2]->[0] =~ m%<td scope="row">DEMO_demo</td>%,
    'Found CustomParam "DEMO_demo" macro' )
  or explain( $res->[2]->[0], 'CustomParam "DEMO_demo" macro' );
my @c = ( $res->[2]->[0] =~ m%<td scope="row">127.0.0.1</td>%gs );
my @d = ( $res->[2]->[0] =~ m%<th scope="col">%gs );
my @e = ( $res->[2]->[0] =~ m%class="data-epoch">(\d{10})</td>%gs );

## Three entries found
ok( @c == 3, ' -> Three entries found' )
  or explain( $res->[2]->[0], "Number of session(s) found = " . scalar @c );
ok( @d == 5, ' -> Five <th> found' )
  or explain( $res->[2]->[0], "Number of <th> found = " . scalar @d );
ok( @e == 3, ' -> Three epoch found' )
  or explain( $res->[2]->[0], "Number of epoch found = " . scalar @e );
ok( time() - 5 <= $e[0] && $e[0] <= time() + 5, 'Right epoch found' )
  or print STDERR Dumper( $res->[2]->[0] ), time(), " / $1";
count(6);

## GlobalLogout request with bad token
my $bad_query = 'token=1234567890_12345&all=1';
ok(
    $res = $client->_post(
        '/globallogout',
        IO::String->new($bad_query),
        cookie => "lemonldap=$idd",
        length => length($bad_query),
    ),
    'POST /globallogout?all=1'
);
my $json;
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == PE_TOKENEXPIRED, 'Response is PE_TOKENEXPIRED' )
  or explain( $json, "error => 82" );
count(3);

## GlobalLogout request for 'dwho'
$query .= '&all=1';
ok(
    $res = $client->_post(
        '/globallogout',
        IO::String->new($query),
        cookie => "lemonldap=$idd",
        length => length($query),
        accept => 'text/html',
    ),
    'POST /globallogout?all=1'
);
ok( $res->[2]->[0] =~ m%<span trmsg="47"></span>%, 'Found PE_LOGOUT_OK' )
  or explain( $res->[2]->[0], "PE_LOGOUT_OK" );
$nbr = count_sessions();
ok( $nbr == 0, "No session found" )
  or explain("Number of session(s) found = $nbr");
count(3);

## Test GlobalLogout request
# Try to auth: first request
ok(
    $res = $client->_post(
        '/', IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html'
    ),
    'Post user/password 1'
);
expectRedirection( $res, 'http://auth.example.com/' );
$idd = expectCookie($res);

# Try to auth: second request
ok(
    $res = $client->_post(
        '/', IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html'
    ),
    'Post user/password 2'
);
expectRedirection( $res, 'http://auth.example.com/' );

# Try to auth: third request
ok(
    $res = $client->_post(
        '/', IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html'
    ),
    'Post user/password 3'
);
expectRedirection( $res, 'http://auth.example.com/' );

$nbr = count_sessions();
ok( $nbr == 3, "Three sessions found" )
  or explain("Number of session(s) found = $nbr");
count(4);

# Try to auth: forth request
ok(
    $res = $client->_post(
        '/', IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html'
    ),
    'Post user/password 4'
);
my $id = expectCookie($res);
ok(
    $res = $client->_delete(
        '/session/my', cookie => "lemonldap=$id",
    ),
    'DELETE /session/my'
);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{result} == 1, 'Session removed' )
  or explain( $res, "result == $res->{result}" );
count(4);

# GlobalLogout
ok(
    $res = $client->_delete(
        '/sessions/my', cookie => "lemonldap=$idd",
    ),
    'DELETE /sessions/my'
);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{result} == 2, 'Two sessions removed' )
  or explain( $res, "result == $res->{result}" );
$nbr = count_sessions();
ok( $nbr == 1, "One remaining session found" )
  or explain("Number of session(s) found = $nbr");
count(4);
$client->logout($idd);

clean_sessions();

done_testing( count() );
