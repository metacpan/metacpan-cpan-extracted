use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';
my $maintests = 41;

SKIP: {
    eval {
        require Convert::Base32;
        require Crypt::U2F::Server::Simple;
        require Authen::U2F::Tester;
    };
    if ($@) {
        skip 'Missing libraries', $maintests;
    }
    use_ok('Lemonldap::NG::Common::FormEncode');
    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel               => 'error',
                utotp2fActivation      => 1,
                totp2fSelfRegistration => 1,
                u2fSelfRegistration    =>
                  '$_2fDevices =~ /"type":\s*"(?:TOTP|U2F)"/s',
                loginHistoryEnabled => 1,
                authentication      => 'Demo',
                userDB              => 'Same',
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

    # TOTP form
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    expectRedirection( $res, qr#/2fregisters/totp$# );
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
    ok( $key   = $res->{secret}, 'Found secret' );
    ok( $token = $res->{token},  'Found token' );
    $key = Convert::Base32::decode_base32($key);

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
    ok( $res->{result} = 1, 'Key is registered' );

    # Try to sign-in
    $client->logout($id);
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/utotp2fcheck', 'token' );
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/utotp2fcheck', IO::String->new($query),
            length => length($query),
        ),
        'Post code'
    );
    $id = expectCookie($res);

    # U2F form
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    expectOK($res);
    ok( $res->[2]->[0] =~ m#<a.*href="/2fregisters/u"#, 'Get U2F choice' )
      or explain( $res->[2]->[0], '<a href="/2fregisters/u">' );

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
    ok( $r->is_success, ' Good challenge value' ) or diag( $r->error_message );

    my $registrationData = JSON::to_json( {
            clientData       => $r->client_data,
            errorCode        => 0,
            registrationData => $r->registration_data,
            version          => "U2F_V2"
        }
    );
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

    # Try to sign-in with TOTP
    $client->logout($id);

    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho&checkLogins=1'),
            length => 37,
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Auth query'
    );
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/utotp2fcheck', 'token', 'checkLogins' );
    ok( $res->[2]->[0] =~ /input name="code"/, ' get TOTP form' );

    # Use TOTP
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/utotp2fcheck', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    expectOK($res);
    $id = expectCookie($res);

    ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
      or explain( $res->[2]->[0], 'trspan="noHistory"' );
    my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
    ok( @c == 3, 'Three entries found' );
    $client->logout($id);

    # Try to sign-in with U2F
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho&checkLogins=1'),
            length => 37,
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Auth query'
    );
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/utotp2fcheck', 'token', 'checkLogins' );

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
    ok( $r->is_success, ' Good challenge value' ) or diag( $r->error_message );
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
            '/utotp2fcheck', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Push U2F signature'
    );

    expectOK($res);

    # See https://github.com/mschout/perl-authen-u2f-tester/issues/2
    if ( $Authen::U2F::Tester::VERSION >= 0.03 ) {
        $id = expectCookie($res);
        ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
          or explain( $res->[2]->[0], 'trspan="noHistory"' );
        my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
        ok( @c == 4, 'Four entries found' );
        $client->logout($id);
    }
    else {
        count(1);
        pass(
'Authen::2F::Tester-0.02 signatures are not recognized by Yubico library'
        );
    }
}
count($maintests);

clean_sessions();

done_testing( count() );
