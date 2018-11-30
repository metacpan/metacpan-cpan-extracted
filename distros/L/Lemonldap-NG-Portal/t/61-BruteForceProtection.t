use Test::More;
use strict;
use IO::String;
use Data::Dumper;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new(
    {
        ini => {
            logLevel                  => 'error',
            authentication            => 'Demo',
            userDB                    => 'Same',
            loginHistoryEnabled       => 1,
            bruteForceProtection      => 1,
            bruteForceProtectionTempo => 5,
        }
    }
);

## First successful connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);
my $id1 = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

$client->logout($id1);

## Second successful connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);
$id1 = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

$client->logout($id1);

## First failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23
    ),
    'Auth query'
);
count(1);
expectReject($res);

## Second failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23
    ),
    'Auth query'
);
count(1);
expectReject($res);

## Third failed connection -> rejected
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/, 'Protection enabled' );
count(1);
sleep 1;

## Fourth failed connection -> Rejected
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/, 'Protection enabled' );
count(1);
sleep 2;

## Third successful connection -> Rejected
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/, 'Protection enabled' );
count(1);
sleep 3;

## Fourth successful connection -> Accepted
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&checkLogins=1'),
        length => 37,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);
$id1 = expectCookie($res);

ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
  or print STDERR Dumper( $res->[2]->[0] );

my @c  = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
my @cf = ( $res->[2]->[0] =~ /PE5<\/td>/gs );

# History with 5 entries
ok( @c == 7,  ' -> Seven entries found' );
ok( @cf == 4, "  -> Four 'failedLogin' entries found" );
count(3);

$client->logout($id1);
clean_sessions();

done_testing( count() );
