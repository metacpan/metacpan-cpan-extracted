use warnings;
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

## Second failed login -> now locked (maxFailed=2, this is the 2nd attempt)
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '2nd Bad Auth query -> locked'
);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%(\d) <span trspan="seconds">seconds</span>%,
    "LockTime = $1" );
ok( $1 <= 5 && $1 >= 1, 'LockTime in range' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

# Waiting
Time::Fake->offset("+2s");

## Try to connect while still locked
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query while locked'
);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%(\d) <span trspan="seconds">seconds</span>%,
    "LockTime = $1" );

# With fix #3561: blocked attempts not stored, countFailed stays 1
# lockTimes[1]=5, delta=2 → remaining ~3s
ok( $1 <= 4 && $1 >= 1, 'LockTime in range' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

# Waiting - lock expired (5s from t=0, now t=8)
Time::Fake->offset("+8s");

## Lock expired, bad password → new failure stored
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    'Bad Auth after lock expired'
);

# delta=8 > 5 → not blocked, just bad credential, stored → count=2
ok( $res->[2]->[0] =~ /<span trmsg="5"><\/span>/,
    'Bad credential (lock expired)' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

## Immediate retry triggers new lock
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    'Immediate retry triggers lock'
);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%(\d{1,2}) <span trspan="seconds">seconds</span>%,
    "LockTime = $1" );

# countFailed=2 → lockTimes[2]=10
ok( $1 <= 12 && $1 >= 5, 'LockTime in range (~10s)' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

# Waiting - lock expired (10s from t=8, now t=20)
Time::Fake->offset("+20s");

## Lock expired, try to connect
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query after lock expired'
);
count(1);
$id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );
$client->logout($id);

# Waiting - history should have expired by now
Time::Fake->offset("+4000s");

## Failed login after long wait - history cleared
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    'Bad Auth after history expired'
);
ok( $res->[2]->[0] =~ /<span trmsg="5"><\/span>/, 'Bad credential' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

## Second failed - now locked (maxFailed=2, this is the 2nd attempt)
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    'Second Bad Auth triggers lock'
);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%(\d) <span trspan="seconds">seconds</span>%,
    "LockTime = $1" );

# countFailed=1 → lockTimes[1]=5 (first non-zero lock time after maxFailed=2 zeros)
ok( $1 <= 6 && $1 >= 1, 'LockTime in range (~5s)' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

clean_sessions();

done_testing( count() );
