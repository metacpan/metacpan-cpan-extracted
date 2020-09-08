use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel            => 'error',
            authentication      => 'Demo',
            userDB              => 'Same',
            loginHistoryEnabled => 1,
            brutForceProtection => 0,
            portalMainLogo      => 'common/logos/logo_llng_old.png',
            requireToken        => 0,
            impersonationRule   => 1,
        }
    }
);

## Try to authenticate with bad password
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=rtyler&password=relytr'),
        length => 27
    ),
    'Auth query'
);
count(1);
expectReject($res);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

$query =~ s/user=/user=rtyler/;
$query =~ s/password=/password=rtyler/;

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
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
count(1);
expectOK($res);
expectAuthenticatedAs( $res, 'rtyler' );
$client->logout($id);

## Try to Impersonate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

$query =~ s/user=/user=rtyler/;
$query =~ s/password=/password=rtyler/;
$query =~ s/spoofId=/spoofId=dwho/;
$query .= '&checkLogins=1';

ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
$id = expectCookie($res);
ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' );
count(2);

# History with 5 entries and 10 custom values
my @c  = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
my @cf = ( $res->[2]->[0] =~ /PE5<\/td>/gs );
ok( @c == 3,  ' -> Three entries found' );
ok( @cf == 1, "  -> One 'failedLogin' entry found" )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

$client->logout($id);
clean_sessions();

done_testing( count() );
