use warnings;
use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing';
    }
    my $res;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                             => 'error',
                authentication                       => 'Demo',
                userDB                               => 'Same',
                requireToken                         => 0,
                loginHistoryEnabled                  => 1,
                bruteForceProtection                 => 1,
                bruteForceProtectionIncrementalTempo => 1,
                bruteForceProtectionMaxLockTime      => 300,
                totp2fSelfRegistration               => 1,
                totp2fActivation                     => 1,
                failedLoginNumber                    => 4,
                bruteForceProtectionMaxFailed        => 0
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

    # JS query
    ok(
        $res = $client->_post(
            '/2fregisters/totp/getkey',
            IO::String->new(''),
            cookie => "lemonldap=$id",
            length => 0,
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Get new key'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    my ( $key, $token );
    ok( $key   = $res->{secret}, 'Found secret' );
    ok( $token = $res->{token},  'Found token' );
    $key = Convert::Base32::decode_base32($key);
    count(4);

    # Post code
    my $code;
    ok( $code = getTotp($key), 'Code' );
    ok( $code =~ /^\d{6}$/,    'Code contains 6 digits' );
    my $s = "code=$code&token=$token";
    ok(
        $res = $client->_post(
            '/2fregisters/totp/verify',
            IO::String->new($s),
            length => length($s),
            cookie => "lemonldap=$id",
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Post code'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{result} == 1, 'Key is registered' );
    count(5);
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
    ok( $res->[2]->[0] =~ /<span trmsg="5"><\/span>/, 'Bad credential' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(2);

    ## Second failed connection
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
    ok( $res->[2]->[0] =~ m%(\d{2}) <span trspan="seconds">seconds</span>%,
        "LockTime = $1" );
    ok( $1 <= 31 && $1 >= 25, 'LockTime in range (~30s)' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(4);

    # Waiting
    Time::Fake->offset("+3s");
    ## Try to connect
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=ohwd'),
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

    # With fix #3561: blocked attempts not stored, countFailed stays 1
    # lockTimes[1]=30, delta=3 → remaining ~27s
    ok( $1 <= 28 && $1 >= 22, 'LockTime in range (~27s)' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(4);

    # Waiting - lock expired (30s from t=0, now t=35)
    Time::Fake->offset("+35s");

    ## Third failed connection - lock expired, bad credential stored (count→2)
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=ohwd'),
            length => 23,
            accept => 'text/html',
        ),
        '3rd Bad Auth query (lock expired)'
    );
    ok(
        $res->[2]->[0] =~ /<span trmsg="5"><\/span>/,
        'Bad credential (lock expired, failure stored)'
    ) or print STDERR Dumper( $res->[2]->[0] );
    count(2);

    ## Immediate retry → countFailed=2, lockTimes[2]=60 → PE_WAIT
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=ohwd'),
            length => 23,
            accept => 'text/html',
        ),
        'Immediate retry triggers new lock'
    );
    ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
        'Rejected -> Protection enabled' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%(\d{2}) <span trspan="seconds">seconds</span>%,
        "LockTime = $1" );

    # countFailed=2 → lockTimes[2]=60
    ok( $1 <= 61 && $1 >= 55, 'LockTime in range (~60s)' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(4);

    # Waiting - lock expired (60s from t=35, now t=100)
    Time::Fake->offset("+100s");
    ## Try to connect with good password
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );
    ok( $res->[2]->[0] =~ /<span trspan="enterTotpCode">/, 'Enter TOTP code' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(2);

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/totp2fcheck', 'token' );
    ok( $code = getTotp($key), 'Code' );
    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    count(2);
    $id = expectCookie($res);
    expectRedirection( $res, 'http://auth.example.com/' );
    $client->logout($id);
}
clean_sessions();

done_testing( count() );
