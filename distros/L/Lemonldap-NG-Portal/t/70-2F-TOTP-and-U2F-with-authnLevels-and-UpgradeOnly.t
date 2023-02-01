use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';
my $maintests = 62;

SKIP: {
    eval {
        require Convert::Base32;
        require Crypt::U2F::Server;
        require Authen::U2F::Tester;
    };
    if ( $@ or $Crypt::U2F::Server::VERSION < 0.42 ) {
        skip 'Missing libraries', $maintests;
    }
    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel               => 'error',
                checkUser              => 1,
                sfOnlyUpgrade          => 1,
                totp2fSelfRegistration => 1,
                totp2fActivation       => 1,
                totp2fAuthnLevel       => 3,
                u2fSelfRegistration    => 1,
                u2fActivation          => 1,
                u2fAuthnLevel          => 4,
                max2FDevices           => 3,
                handlerInternalCache   => 5
            }
        }
    );
    my $res;

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

    # Try to register TOTP
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => "lemonldap=$id",
            accept => 'text/html'
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
    my ( $key, $token, $code );
    ok( $key   = $res->{secret}, 'Found secret' );
    ok( $token = $res->{token},  'Found token' );
    $key = Convert::Base32::decode_base32($key);

    # Post code
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    ok( $code =~ /^\d{6}$/, 'Code contains 6 digits' );
    my $s = "code=$code&token=$token&TOTPName=MyTOTP";
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

    Time::Fake->offset("+10s");

    # Try to register U2F (higher level SFA)
    ok(
        $res = $client->_get(
            '/2fregisters/u',
            cookie => "lemonldap=$id",
            accept => 'text/html'
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
            length => 0
        ),
        'Try to get registration challenge -> rejected'
    );
    expectBadRequest($res);
    my $data;
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( ( $data->{error} eq 'notAuthorizedAuthLevel' ), 'AuthLevel error' )
      or explain( $data, 'authLevel' );

    # Try to upgrade from 2fManager
    # -----------------------------
    ok(
        $res = $client->_get(
            '/upgradesession',
            query =>
'forceUpgrade=1&url=aHR0cDovL2F1dGguZXhhbXBsZS5jb20vMmZyZWdpc3RlcnM=',
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Upgrade session query from 2fManager'
    );

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/upgradesession', 'confirm', 'url',
        'forceUpgrade' );

    # Accept session upgrade
    ok(
        $res = $client->_post(
            '/upgradesession',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Accept session upgrade query'
    );

    # POST TOTP
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

    # Check authLevel (TOTP -> 3)
    ok(
        $res = $client->_get(
            '/checkuser', cookie => "lemonldap=$id",
        ),
        'CheckUser',
    );
    ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    my @authLevel = map { $_->{key} eq 'authenticationLevel' ? $_ : () }
      @{ $res->{ATTRIBUTES} };
    ok( $authLevel[0]->{value} == 3, 'AuthenticationLevel == 3' )
      or explain( $authLevel[0]->{value}, 'AuthenticationLevel value == 3' );

    Time::Fake->offset("+20s");

    # Try to register U2F (higher level SFA)
    # --------------------------------------
    ok(
        $res = $client->_get(
            '/2fregisters/u',
            cookie => "lemonldap=$id",
            accept => 'text/html'
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
            length => 0
        ),
        'Try to get registration challenge'
    );
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
    ( $host, $url, $query );
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

    Time::Fake->offset("+30s");

    # Try to register U2F (higher level SFA)
    # --------------------------------------
    ok(
        $res = $client->_get(
            '/2fregisters/u',
            cookie => "lemonldap=$id",
            accept => 'text/html'
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
            length => 0
        ),
        'Try to get registration challenge -> rejected'
    );
    expectBadRequest($res);
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( ( $data->{error} eq 'notAuthorizedAuthLevel' ), ' AuthLevel error' )
      or explain( $data, 'authLevel' );

    # Try to upgrade from 2fManager
    # -----------------------------
    ok(
        $res = $client->_get(
            '/upgradesession',
            query =>
'forceUpgrade=1&url=aHR0cDovL2F1dGguZXhhbXBsZS5jb20vMmZyZWdpc3RlcnM=',
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Upgrade session query from 2fManager'
    );

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/upgradesession', 'confirm', 'url',
        'forceUpgrade' );

    # Accept session upgrade
    ok(
        $res = $client->_post(
            '/upgradesession',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Accept session upgrade query'
    );

    # POST U2F
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

        # Check authLevel (U2F -> 4)
        ok(
            $res = $client->_get(
                '/checkuser', cookie => "lemonldap=$id",
            ),
            'CheckUser',
        );
        ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
          or print STDERR "$@\n" . Dumper($res);
        @authLevel = map { $_->{key} eq 'authenticationLevel' ? $_ : () }
          @{ $res->{ATTRIBUTES} };
        ok( $authLevel[0]->{value} == 4, 'AuthenticationLevel == 4' )
          or
          explain( $authLevel[0]->{value}, 'AuthenticationLevel value == 4' );
    }
    else {
        count(1);
        pass(
'Authen::2F::Tester-0.02 signatures are not recognized by Yubico library'
        );
    }

    Time::Fake->offset("+40s");

    # Try to register U2F (higher level SFA)
    # --------------------------------------
    ok(
        $res = $client->_get(
            '/2fregisters/u',
            cookie => "lemonldap=$id",
            accept => 'text/html'
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
            length => 0
        ),
        'Try to get registration challenge'
    );
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( ( $data->{challenge} and $data->{appId} ), ' Get challenge and appId' )
      or explain( $data, 'challenge and appId' );

    # Build U2F tester
    $tester = Authen::U2F::Tester->new(
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
    $r = $tester->register( $data->{appId}, $data->{challenge} );
    ok( $r->is_success, ' Good challenge value' )
      or diag( $r->error_message );

    $registrationData = JSON::to_json( {
            clientData       => $r->client_data,
            errorCode        => 0,
            registrationData => $r->registration_data,
            version          => "U2F_V2"
        }
    );
    ( $host, $url, $query );
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

    # Try to register U2F (more than max)
    # -----------------------------------
    ok(
        $res = $client->_get(
            '/2fregisters/u',
            cookie => "lemonldap=$id",
            accept => 'text/html'
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
            length => 0
        ),
        'Try to get registration challenge -> rejected'
    );
    expectBadRequest($res);
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( ( $data->{error} eq 'maxNumberOf2FDevicesReached' ),
        'NumberOf2FDevices error' )
      or explain( $data, 'maxNumberOf2FDevices' );

    $client->logout($id);
}
count($maintests);
clean_sessions();

done_testing( count() );
