use Test::More;
use strict;
use IO::String;
use Data::Dumper;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                      => 'error',
            authentication                => 'Demo',
            userDB                        => 'Same',
            loginHistoryEnabled           => 1,
            bruteForceProtection          => 1,
            bruteForceProtectionTempo     => 5,
            bruteForceProtectionMaxFailed => 4,
            failedLoginNumber             => 6,
            successLoginNumber            => 4,
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
    '1st Auth query'
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
    '2nd Auth query'
);
count(1);
$id1 = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

$client->logout($id1);

## Third successful connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '3rd Auth query'
);
count(1);
$id1 = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

$client->logout($id1);

## Forth successful connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '4th Auth query'
);
count(1);
$id1 = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

$client->logout($id1);

## Fifth successful connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '5th Auth query'
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
    '1st Bad Auth query'
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
    '2nd Bad Auth query'
);
count(1);
expectReject($res);

## Third failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23
    ),
    '3rd Bad Auth query'
);
count(1);
expectReject($res);

## Forth failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23
    ),
    '4th Bad Auth query'
);
count(1);
expectReject($res);

## Fifth failed connection -> rejected
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '5th Bad Auth query'
);
count(1);

ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' );
count(1);

# Waiting
Time::Fake->offset("+1s");

## Sixth failed connection -> Rejected
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '6th Bad Auth query'
);
count(1);

ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' );
count(1);

# Waiting
Time::Fake->offset("+3s");

## Sixth successful connection -> Rejected
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    '6th Auth query'
);
count(1);

ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' );
count(1);

# Waiting
Time::Fake->offset("+6s");

## Seventh successful connection -> Accepted
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&checkLogins=1'),
        length => 37,
        accept => 'text/html',
    ),
    '7th Auth query'
);
count(1);
$id1 = expectCookie($res);

ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /<caption trspan="lastFailedLoginsCaptionLabel">/,
    'History found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ /<caption trspan="lastLoginsCaptionLabel">/,
    'History found' )
  or print STDERR Dumper( $res->[2]->[0] );

my @c  = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
my @cf = ( $res->[2]->[0] =~ /PE5<\/td>/gs );

# History with 8 entries
ok( @c == 8, ' -> Eight entries found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( @cf == 4, "  -> Four 'failedLogin' entries found" )
  or print STDERR Dumper( $res->[2]->[0] );
count(5);

$client->logout($id1);
clean_sessions();

done_testing( count() );
