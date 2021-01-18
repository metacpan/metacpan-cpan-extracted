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
            failedLoginNumber                    => 6,
            bruteForceProtectionMaxLockTime      => 600,
            bruteForceProtectionLockTimes => '5 , 500, bad ,20, -10, 700',
            bruteForceProtectionMaxFailed => 2,
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

## First allowed failed login
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '1st allowed Bad Auth query'
);
ok( $res->[2]->[0] =~ /<span trmsg="5"><\/span>/, 'Bad credential' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

## Second allowed failed login
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '2nd allowed Bad Auth query'
);
ok( $res->[2]->[0] =~ /<span trmsg="5"><\/span>/, 'Bad credential' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

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
ok( $res->[2]->[0] =~ m%(\d) <span trspan="seconds">seconds</span>%,
    "LockTime = $1" );
ok( $1 <= 5 && $1 >= 3, 'LockTime in range' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

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
ok( $res->[2]->[0] =~ m%(\d) <span trspan="seconds">seconds</span>%,
    "LockTime = $1" );
ok( $1 <= 6 && $1 >= 3, 'LockTime in range' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

# Waiting
Time::Fake->offset("+8s");

## Second failed connection
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
ok( $res->[2]->[0] =~ m%(\d{2}) <span trspan="seconds">seconds</span>%,
    "LockTime = $1" );
ok( $1 <= 18 && $1 >= 15, 'LockTime in range' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

# Waiting
Time::Fake->offset("+20s");

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
ok( $res->[2]->[0] =~ m%(\d{3}) <span trspan="seconds">seconds</span>%,
    "LockTime = $1" );
ok( $1 <= 490 && $1 >= 480, 'LockTime in range' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

# Waiting
Time::Fake->offset("+510s");

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

# Waiting
Time::Fake->offset("+1000s");

## Allowed failed login
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '2nd allowed Bad Auth query'
);
ok( $res->[2]->[0] =~ /<span trmsg="5"><\/span>/, 'Bad credential' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

## Forth failed connection
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
ok( $res->[2]->[0] =~ m%(\d{3}) <span trspan="seconds">seconds</span>%,
    "LockTime = $1" );
ok( $1 <= 5000 && $1 >= 490, 'LockTime in range' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

clean_sessions();

done_testing( count() );
