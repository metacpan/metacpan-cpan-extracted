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
            '/2fregisters/totp/getkey', IO::String->new(''),
            cookie => "lemonldap=$id",
            length => 0,
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
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    ok( $code =~ /^\d{6}$/, 'Code contains 6 digits' );
    my $s = "code=$code&token=$token";
    ok(
        $res = $client->_post(
            '/2fregisters/totp/verify',
            IO::String->new($s),
            length => length($s),
            cookie => "lemonldap=$id",
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
    ok( $1 <= 15 && $1 >= 13, 'LockTime in range' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(4);

    # Waiting
    Time::Fake->offset("+3s");
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
    ok( $res->[2]->[0] =~ m%(\d{2}) <span trspan="seconds">seconds</span>%,
        "LockTime = $1" );
    ok( $1 < 30 && $1 >= 25, 'LockTime in range' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(4);

    # Waiting
    Time::Fake->offset("+6s");
    ## Third failed connection
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
    ok( $res->[2]->[0] =~ m%(\d{2}) <span trspan="seconds">seconds</span>%,
        "LockTime = $1" );
    ok( $1 < 60 && $1 >= 55, 'LockTime in range' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(4);

    # Waiting
    Time::Fake->offset("+70s");
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
    ok( $res->[2]->[0] =~ /<span trspan="enterTotpCode">/, 'Enter TOTP code' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(2);

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/totp2fcheck', 'token' );
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
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
