use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                             => 'error',
            authentication                       => 'Demo',
            userDB                               => 'Same',
            loginHistoryEnabled                  => 1,
            bruteForceProtection                 => 1,
            bruteForceProtectionIncrementalTempo => 1,
            failedLoginNumber                    => 4,
            bruteForceProtectionMaxLockTime      => 300,
            bruteForceProtectionLockTimes        => '5 500 bad 20 10 ',
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
my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );
$client->logout($id);

## First failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '1st Bad Auth query'
);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%5 <span trspan="seconds">seconds</span>%,
    'LockTime = 5' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

# Waiting
Time::Fake->offset("+4s");

## Try to connect
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%5 <span trspan="seconds">seconds</span>%,
    'LockTime = 5' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

## Second failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '2nd Bad Auth query'
);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%10 <span trspan="seconds">seconds</span>%,
    'LockTime = 10' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

# Waiting
Time::Fake->offset("+15s");
## Try to connect
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
$id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );
$client->logout($id);

## Third failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '3rd Bad Auth query'
);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%20 <span trspan="seconds">seconds</span>%,
    'LockTime = 20' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

## Forth failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '4th Bad Auth query'
);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%300 <span trspan="seconds">seconds</span>%,
    'LockTime = 300' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

## Fifth failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '5th Bad Auth query'
);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%300 <span trspan="seconds">seconds</span>%,
    'LockTime = 300' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

# Waiting
Time::Fake->offset("+320s");
## Try to connect
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
$id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );
$client->logout($id);

clean_sessions();

done_testing( count() );
