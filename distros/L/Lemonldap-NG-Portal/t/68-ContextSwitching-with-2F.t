use Test::More;
use strict;
use IO::String;
use JSON qw(to_json from_json);

require 't/test-lib.pm';

my $maintests = 76;

SKIP: {
    require Lemonldap::NG::Common::TOTP;
    eval { require Crypt::U2F::Server; require Authen::U2F::Tester };
    if ( $@ or $Crypt::U2F::Server::VERSION < 0.42 ) {
        skip 'Missing U2F libraries', $maintests;
    }
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing';
    }
    my $res;
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel             => 'error',
                authentication       => 'Demo',
                userDB               => 'Same',
                portalMainLogo       => 'common/logos/logo_llng_old.png',
                contextSwitchingRule => 1,
                contextSwitchingStopWithLogout         => 0,
                contextSwitchingAllowed2fModifications => 0,
                totp2fSelfRegistration                 => 1,
                totp2fActivation                       => 1,
                u2fSelfRegistration                    => 1,
                u2fActivation                          => 1,
            }
        }
    );

    ## Try to authenticate
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password' );

    $query =~ s/user=/user=rtyler/;
    $query =~ s/password=/password=rtyler/;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Auth query'
    );
    my $id = expectCookie($res);
    expectRedirection( $res, 'http://auth.example.com/' );

    # Get Menu
    # ------------------------
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Get Menu',
    );
    expectOK($res);
    ok(
        $res->[2]->[0] =~
          m%<span trspan="connectedAs">Connected as</span> rtyler%,
        'Connected as rtyler'
    ) or print STDERR Dumper( $res->[2]->[0] );
    expectAuthenticatedAs( $res, 'rtyler' );
    ok(
        $res->[2]->[0] =~
          m%<span trspan="contextSwitching_ON">contextSwitching_ON</span>%,
        'contextSwitching allowed'
    ) or print STDERR Dumper( $res->[2]->[0] );

    ## Try to register a TOTP
    # TOTP form
    my ( $key, $token, $code );
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );

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
    ok( $key   = $res->{secret}, 'Found secret' ) or print STDERR Dumper($res);
    ok( $token = $res->{token},  'Found token' )  or print STDERR Dumper($res);
    ok( $res->{user} eq 'rtyler', 'Found user' )
      or print STDERR Dumper($res);
    $key = Convert::Base32::decode_base32($key);

    # Post code
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

    ## Try to register an U2F key
    ok(
        $res = $client->_get(
            '/2fregisters/u',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /u2fregistration\.(?:min\.)?js/, 'Found U2F js' );
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );

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
    ok( $data->{result} == 1, 'U2F key is registered' )
      or explain( $data, '"result":1' );

    $client->logout($id);

    ## Try to authenticate
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password' );

    $query =~ s/user=/user=rtyler/;
    $query =~ s/password=/password=rtyler/;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
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

    # Get Menu
    # ------------------------
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Get Menu',
    );
    expectOK($res);
    expectAuthenticatedAs( $res, 'rtyler' );

    # Try to switch context 'dwho'
    # ContextSwitching form
    ok(
        $res = $client->_get(
            '/switchcontext',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'ContextSwitching form',
    );

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/switchcontext', 'spoofId' );
    ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
        'Found trspan="contextSwitching_ON"' )
      or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );

    ## POST form
    $query =~ s/spoofId=/spoofId=dwho/;
    ok(
        $res = $client->_post(
            '/switchcontext',
            IO::String->new($query),
            cookie => "lemonldap=$id",
            length => length($query),
            accept => 'text/html',
        ),
        'POST switchcontext'
    );
    expectRedirection( $res, 'http://auth.example.com/' );
    my $id2 = expectCookie($res);
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id2",
            accept => 'text/html'
        ),
        'Get Menu',
    );
    expectAuthenticatedAs( $res, 'dwho' );
    ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_OFF">%,
        'Found trspan="contextSwitching_OFF"' )
      or explain( $res->[2]->[0], 'trspan="contextSwitching_OFF"' );

    # 2fregisters
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id2",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $res->[2]->[0] =~ /<span id="msg" trspan="notAuthorized">/,
        'Found choose 2F' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] !~ m%<span device=\'(TOTP|U2F)\' epoch=\'\d{10}\'%g,
        'No 2F device found' )
      or print STDERR Dumper( $res->[2]->[0] );

    ## Try to register a TOTP
    # TOTP form
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => "lemonldap=$id2",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' )
      or print STDERR Dumper( $res->[2]->[0] );

    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );

    # JS query
    ok(
        $res = $client->_post(
            '/2fregisters/totp/getkey', IO::String->new(''),
            cookie => "lemonldap=$id2",
            length => 0,
        ),
        'Get new key'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{error} eq 'notAuthorized', 'Not authorized to register a TOTP' )
      or explain( $res, 'Bad result' );

    # Try to unregister TOTP
    ok(
        $res = $client->_post(
            '/2fregisters/totp/delete',
            IO::String->new("epoch=1234567890"),
            length => 16,
            cookie => "lemonldap=$id2",
        ),
        'Delete TOTP query'
    );
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok(
        $data->{error} eq 'notAuthorized',
        'Not authorized to unregister a TOTP'
    ) or explain( $data, 'Bad result' );

    # Try to verify TOTP
    $s = "code=123456&token=1234567890&TOTPName=myTOTP";
    ok(
        $res = $client->_post(
            '/2fregisters/totp/verify',
            IO::String->new($s),
            length => length($s),
            cookie => "lemonldap=$id2",
        ),
        'Post code'
    );
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( $data->{error} eq 'notAuthorized', 'Not authorized to verify a TOTP' )
      or explain( $data, 'Bad result' );

    ## Try to register an U2F key
    # U2F form
    ok(
        $res = $client->_get(
            '/2fregisters/u',
            cookie => "lemonldap=$id2",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok( $res->[2]->[0] =~ /u2fregistration\.(?:min\.)?js/, 'Found U2F js' );
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );

    # Ajax registration request
    ok(
        $res = $client->_post(
            '/2fregisters/u/register', IO::String->new(''),
            accept => 'application/json',
            cookie => "lemonldap=$id2",
            length => 0,
        ),
        'Get registration challenge'
    );
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok(
        $data->{error} eq 'notAuthorized',
        'Not authorized to register an U2F key'
    ) or explain( $data, 'Bad result' );

    # Try to unregister U2F key
    ok(
        $res = $client->_post(
            '/2fregisters/u/delete',
            IO::String->new("epoch=1234567890"),
            length => 16,
            cookie => "lemonldap=$id2",
        ),
        'Delete U2F key query'
    );
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok(
        $data->{error} eq 'notAuthorized',
        'Not authorized to unregister an U2F key'
    ) or explain( $data, 'Bad result' );

    $client->logout($id);
    $client->logout($id2);

    ## Try to authenticate
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password' );

    $query =~ s/user=/user=dwho/;
    $query =~ s/password=/password=dwho/;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Auth query'
    );
    $id = expectCookie($res);
    expectRedirection( $res, 'http://auth.example.com/' );

    # Get Menu
    # ------------------------
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Get Menu',
    );
    expectOK($res);
    ok(
        $res->[2]->[0] =~
          m%<span trspan="connectedAs">Connected as</span> dwho%,
        'Connected as dwho'
    ) or print STDERR Dumper( $res->[2]->[0] );
    expectAuthenticatedAs( $res, 'dwho' );
    ok(
        $res->[2]->[0] =~
          m%<span trspan="contextSwitching_ON">contextSwitching_ON</span>%,
        'contextSwitching allowed'
    ) or print STDERR Dumper( $res->[2]->[0] );

    # Try to switch context 'rtyler'
    # ContextSwitching form
    ok(
        $res = $client->_get(
            '/switchcontext',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'ContextSwitching form',
    );

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/switchcontext', 'spoofId' );
    ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_ON">%,
        'Found trspan="contextSwitching_ON"' )
      or explain( $res->[2]->[0], 'trspan="contextSwitching_ON"' );

    ## POST form
    $query =~ s/spoofId=/spoofId=rtyler/;
    ok(
        $res = $client->_post(
            '/switchcontext',
            IO::String->new($query),
            cookie => "lemonldap=$id",
            length => length($query),
            accept => 'text/html',
        ),
        'POST switchcontext'
    );
    expectRedirection( $res, 'http://auth.example.com/' );
    $id2 = expectCookie($res);
    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id2",
            accept => 'text/html'
        ),
        'Get Menu',
    );
    expectAuthenticatedAs( $res, 'rtyler' );
    ok( $res->[2]->[0] =~ m%<span trspan="contextSwitching_OFF">%,
        'Found trspan="contextSwitching_OFF"' )
      or explain( $res->[2]->[0], 'trspan="contextSwitching_OFF"' );

    # 2fregisters
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id2",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $res->[2]->[0] =~ /<span id="msg" trspan="notAuthorized">/,
        'Found choose 2F' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] !~ m%<span device=\'(TOTP|U2F)\' epoch=\'\d{10}\'%g,
        'No 2F device found' )
      or print STDERR Dumper( $res->[2]->[0] );
}

count($maintests);

clean_sessions();
done_testing( count() );
