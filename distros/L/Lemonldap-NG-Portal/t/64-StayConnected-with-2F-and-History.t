use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';
my $res;
my $maintests = 63;

SKIP: {
    eval {
        require Convert::Base32;
        require Crypt::U2F::Server::Simple;
        require Authen::U2F::Tester;
    };
    if ($@) {
        skip 'Missing libraries', $maintests;
    }

    #use_ok('Lemonldap::NG::Common::FormEncode');
    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel               => 'error',
                useSafeJail            => 1,
                stayConnected          => 1,
                loginHistoryEnabled    => 1,
                u2fSelfRegistration    => 1,
                u2fActivation          => 1,
                totp2fSelfRegistration => 1,
                totp2fActivation       => 1,
                portalMainLogo         => 'common/logos/logo_llng_old.png'
            }
        }
    );

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    my $id = expectCookie($res);

    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Get Menu'
    );

    # U2F form
    ok(
        $res = $client->_get(
            '/2fregisters/u',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /u2fregistration\.(?:min\.)?js/, 'Found U2F js' );

    # Ajax registration request
    ok(
        $res = $client->_post(
            '/2fregisters/u/register', IO::String->new(''),
            accept => 'application/json',
            cookie => "lemonldap=$id",
            length => 0,
        ),
        'Get registration challenge'
    );
    expectOK($res);
    my $data;
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( ( $data->{challenge} and $data->{appId} ), ' Get challenge and appId' )
      or explain( $data, 'challenge and appId' );

    # Build U2F tester
    my $tester = Authen::U2F::Tester->new(
        certificate => Crypt::OpenSSL::X509->new_from_string(
            '-----BEGIN CERTIFICATE-----
MIIB6DCCAY6gAwIBAgIJAJKuutkN2sAfMAoGCCqGSM49BAMCME8xCzAJBgNVBAYT
AlVTMQ4wDAYDVQQIDAVUZXhhczEaMBgGA1UECgwRVW50cnVzdGVkIFUyRiBPcmcx
FDASBgNVBAMMC3ZpcnR1YWwtdTJmMB4XDTE4MDMyODIwMTc1OVoXDTI3MTIyNjIw
MTc1OVowTzELMAkGA1UEBhMCVVMxDjAMBgNVBAgMBVRleGFzMRowGAYDVQQKDBFV
bnRydXN0ZWQgVTJGIE9yZzEUMBIGA1UEAwwLdmlydHVhbC11MmYwWTATBgcqhkjO
PQIBBggqhkjOPQMBBwNCAAQTij+9mI1FJdvKNHLeSQcOW4ob3prvIXuEGJMrQeJF
6OYcgwxrVqsmNMl5w45L7zx8ryovVOti/mtqkh2pQjtpo1MwUTAdBgNVHQ4EFgQU
QXKKf+rrZwA4WXDCU/Vebe4gYXEwHwYDVR0jBBgwFoAUQXKKf+rrZwA4WXDCU/Ve
be4gYXEwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNIADBFAiEAiCdOEmw5
hknzHR1FoyFZKRrcJu17a1PGcqTFMJHTC70CIHeCZ8KVuuMIPjoofQd1l1E221rv
RJY1Oz1fUNbrIPsL
-----END CERTIFICATE-----', Crypt::OpenSSL::X509::FORMAT_PEM()
        ),
        key => Crypt::PK::ECC->new(
            \'-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIOdbZw1swQIL+RZoDQ9zwjWY5UjA1NO81WWjwbmznUbgoAoGCCqGSM49
AwEHoUQDQgAEE4o/vZiNRSXbyjRy3kkHDluKG96a7yF7hBiTK0HiRejmHIMMa1ar
JjTJecOOS+88fK8qL1TrYv5rapIdqUI7aQ==
-----END EC PRIVATE KEY-----'
        ),
    );
    my $r = $tester->register( $data->{appId}, $data->{challenge} );
    ok( $r->is_success, ' Good challenge value' )
      or diag( $r->error_message );

    my $registrationData = JSON::to_json( {
            clientData       => $r->client_data,
            errorCode        => 0,
            registrationData => $r->registration_data,
            version          => "U2F_V2"
        }
    );
    my ( $host, $url, $query );
    $query = Lemonldap::NG::Common::FormEncode::build_urlencoded(
        registration => $registrationData,
        challenge    => $res->[2]->[0],
    );

    ok(
        $res = $client->_post(
            '/2fregisters/u/registration', IO::String->new($query),
            length => length($query),
            accept => 'application/json',
            cookie => "lemonldap=$id",
        ),
        'Push registration data'
    );
    expectOK($res);
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( $data->{result} == 1, 'Key is registered' )
      or explain( $data, '"result":1' );

    # TOTP form
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );

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
    ok( $key   = $res->{secret}, 'Found secret' ) or print STDERR Dumper($res);
    ok( $token = $res->{token},  'Found token' )  or print STDERR Dumper($res);
    ok( $res->{user} eq 'dwho', 'Found user' )
      or print STDERR Dumper($res);
    $key = Convert::Base32::decode_base32($key);

    # Post code
    my $code;
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    ok( $code =~ /^\d{6}$/, 'Code contains 6 digits' );
    my $s = "code=$code&token=$token&TOTPName=myTOTP";
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
    ok( $res->{result} == 1, 'TOTP is registered' );

    # Try to authenticate with TOTP
    # -----------------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new(
                'user=dwho&password=dwho&stayconnected=1&checkLogins=1'),
            length => 53
        ),
        'Auth query'
    );
    ( $host, $url, $query ) = expectForm( $res, undef, '/2fchoice', 'token' );
    $query .= '&sf=totp';
    ok(
        $res = $client->_post(
            '/2fchoice',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post TOTP choice'
    );
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/totp2fcheck', 'token' );
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
            length => length($query),
        ),
        'Post code'
    );
    $id = expectCookie($res);
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/registerbrowser', 'fg', 'token' );

    # Push fingerprint
    $query =~ s/fg=/fg=aaa/;
    ok(
        $res = $client->_post(
            '/registerbrowser',
            IO::String->new($query),
            length => length($query),
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Post fingerprint'
    );
    my $cid = expectCookie( $res, 'llngconnection' );

    # History is displayed
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
      or explain( $res->[2]->[0], 'trspan="lastLogins"' );
    my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );

    # History with 2 successLogins
    ok( @c == 2, " -> Two entries found" )
      or explain( $res->[2]->[0], 'Two entries found' );
    ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ),
        'Verify connection' );
    expectAuthenticatedAs( $res, 'dwho' );
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Get Menu'
    );
    ok( $res->[2]->[0] =~ m%<span trspan="yourApps">Your applications</span>%,
        ' Apps menu found' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Try to authenticate with U2F
    # ----------------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new(
                'user=dwho&password=dwho&stayconnected=1&checkLogins=1'),
            length => 53
        ),
        'Auth query'
    );
    ( $host, $url, $query ) = expectForm( $res, undef, '/2fchoice', 'token' );
    $query .= '&sf=u';
    ok(
        $res = $client->_post(
            '/2fchoice',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post U2F choice'
    );
    ( $host, $url, $query ) = expectForm( $res, undef, '/u2fcheck', 'token' );

    # Get challenge
    ok( $res->[2]->[0] =~ /^.*"keyHandle".*$/m, ' get keyHandle' );
    $data = $&;
    eval { $data = JSON::from_json($data) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $data ], 'JSON content' );

    # Build U2F signature
    $r =
      $tester->sign( $data->{appId}, $data->{challenge},
        $data->{registeredKeys}->[0]->{keyHandle} );
    ok( $r->is_success, ' Good challenge value' )
      or diag( $r->error_message );
    my $sign = JSON::to_json( {
            errorCode     => 0,
            signatureData => $r->signature_data,
            clientData    => $r->client_data,
            keyHandle     => $data->{registeredKeys}->[0]->{keyHandle},
        }
    );
    $sign =
      Lemonldap::NG::Common::FormEncode::build_urlencoded( signature => $sign );
    $query =~ s/signature=/$sign/e;
    $query =~ s/challenge=/challenge=$data->{challenge}/;

    # POST result
    ok(
        $res = $client->_post(
            '/u2fcheck',
            IO::String->new($query),
            length => length($query),
        ),
        'Push U2F signature'
    );

    # See https://github.com/mschout/perl-authen-u2f-tester/issues/2
    if ( $Authen::U2F::Tester::VERSION >= 0.03 ) {
        $id = expectCookie($res);
    }
    else {
        count(1);
        pass(
'Authen::2F::Tester-0.02 signatures are not recognized by Yubico library'
        );
    }

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/registerbrowser', 'fg', 'token' );

    # Push fingerprint
    $query =~ s/fg=/fg=aaa/;
    ok(
        $res = $client->_post(
            '/registerbrowser',
            IO::String->new($query),
            length => length($query),
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Post fingerprint'
    );
    $cid = expectCookie( $res, 'llngconnection' );

    # History is displayed
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom main Logo'
    ) or explain( $res->[2]->[0], 'Custom main logo' );
    ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
      or explain( $res->[2]->[0], 'trspan="lastLogins"' );
    @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );

    # History with 3 successLogins
    ok( @c == 3, " -> Three entries found" )
      or explain( $res->[2]->[0], 'Three entries found' );
    ok( $res = $client->_get( '/', cookie => "lemonldap=$id" ),
        'Verify connection' );
    expectAuthenticatedAs( $res, 'dwho' );
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Get Menu'
    );
    ok( $res->[2]->[0] =~ m%<span trspan="yourApps">Your applications</span>%,
        ' Apps menu found' )
      or explain( $res->[2]->[0], 'Apps menu' );

    # Try to connect with persistent connection cookie
    ok(
        $res = $client->_get(
            '/',
            cookie => "llngconnection=$cid",
            accept => 'text/html',
        ),
        'Try to auth with persistent cookie'
    );
    expectOK($res);
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'fg', 'token' );

    # Push fingerprint
    $query =~ s/fg=/fg=aaa/;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            cookie => "llngconnection=$cid",
            length => length($query),
            accept => 'text/html',
        ),
        'Post fingerprint'
    );

    # Try to authenticate with TOTP
    # -----------------------------
    ( $host, $url, $query ) = expectForm( $res, undef, '/2fchoice', 'token' );
    $query .= '&sf=totp';
    ok(
        $res = $client->_post(
            '/2fchoice',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post TOTP choice'
    );
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/totp2fcheck', 'token' );
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
            length => length($query),
        ),
        'Post code'
    );
    $id = expectCookie($res);
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Get Menu'
    );
    expectAuthenticatedAs( $res, 'dwho' );
    ok( $res->[2]->[0] =~ m%<span trspan="yourApps">Your applications</span>%,
        ' Apps menu found' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Try to connect with persistent connection cookie
    ok(
        $res = $client->_get(
            '/',
            cookie => "llngconnection=$cid",
            accept => 'text/html',
        ),
        'Try to auth with persistent cookie'
    );
    expectOK($res);
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'fg', 'token' );

    # Push fingerprint
    $query =~ s/fg=/fg=aaa/;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            cookie => "llngconnection=$cid",
            length => length($query),
            accept => 'text/html',
        ),
        'Post fingerprint'
    );

    # Try to authenticate with U2F
    # -----------------------------
    ( $host, $url, $query ) = expectForm( $res, undef, '/2fchoice', 'token' );
    $query .= '&sf=u';
    ok(
        $res = $client->_post(
            '/2fchoice',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post U2F choice'
    );
    ( $host, $url, $query ) = expectForm( $res, undef, '/u2fcheck', 'token' );

    # Get challenge
    ok( $res->[2]->[0] =~ /^.*"keyHandle".*$/m, ' get keyHandle' );
    $data = $&;
    eval { $data = JSON::from_json($data) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $data ], 'JSON content' );

    # Build U2F signature
    $r =
      $tester->sign( $data->{appId}, $data->{challenge},
        $data->{registeredKeys}->[0]->{keyHandle} );
    ok( $r->is_success, ' Good challenge value' )
      or diag( $r->error_message );
    $sign = JSON::to_json( {
            errorCode     => 0,
            signatureData => $r->signature_data,
            clientData    => $r->client_data,
            keyHandle     => $data->{registeredKeys}->[0]->{keyHandle},
        }
    );
    $sign =
      Lemonldap::NG::Common::FormEncode::build_urlencoded( signature => $sign );
    $query =~ s/signature=/$sign/e;
    $query =~ s/challenge=/challenge=$data->{challenge}/;

    # POST result
    ok(
        $res = $client->_post(
            '/u2fcheck',
            IO::String->new($query),
            length => length($query),
        ),
        'Push U2F signature'
    );

    # See https://github.com/mschout/perl-authen-u2f-tester/issues/2
    if ( $Authen::U2F::Tester::VERSION >= 0.03 ) {
        $id = expectCookie($res);
    }
    else {
        count(1);
        pass(
'Authen::2F::Tester-0.02 signatures are not recognized by Yubico library'
        );
    }
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Get Menu'
    );
    expectAuthenticatedAs( $res, 'dwho' );
    ok( $res->[2]->[0] =~ m%<span trspan="yourApps">Your applications</span>%,
        ' Apps menu found' )
      or print STDERR Dumper( $res->[2]->[0] );

}

count($maintests);
clean_sessions();
done_testing( count() );

