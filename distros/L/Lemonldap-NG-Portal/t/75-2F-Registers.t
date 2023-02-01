use Test::More;
use strict;
use IO::String;
use Data::Dumper;
use MIME::Base64;

require 't/test-lib.pm';
my $maintests = 78;

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }

    eval { require Crypt::U2F::Server; require Authen::U2F::Tester };
    if ( $@ or $Crypt::U2F::Server::VERSION < 0.42 ) {
        skip 'Missing libraries', $maintests;
    }

    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                => 'error',
                totp2fSelfRegistration  => 1,
                totp2fActivation        => 1,
                totp2fAuthnLevel        => 1,
                totp2fLogo              => 'mytotp.png',
                totp2fLabel             => 'My TOTP',
                u2fSelfRegistration     => 1,
                u2fActivation           => 1,
                u2fAuthnLevel           => 5,
                restSessionServer       => 1,
                skipUpgradeConfirmation => 1,
                sfManagerRule           => '$uid eq "dwho"',
                portalMainLogo          => 'common/logos/logo_llng_old.png',
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

    ok(
        $res = $client->_get(
            '/',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Get Menu'
    );
    ok( $res->[2]->[0] =~ m%<span trspan="sfaManager">sfaManager</span>%,
        'sfaManager link found' )
      or print STDERR Dumper( $res->[2]->[0] );

    # TOTP form
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );

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
        $res->[2]->[0] =~
          qr%<img src="/static/common/logos/logo_llng_old\.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%<span id="languages"></span>%,
        'Language icons found' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Register TOTP
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
    expectSessionAttributes( $client, $id, _2f => "totp" );

    # Get 2F register form
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $res->[2]->[0] =~ /2fregistration\.(?:min\.)?js/,
        'Found 2f registration js' );
    ok( $res->[2]->[0] =~ qr%<img src="/static/bootstrap/mytotp.png".*?/>%,
        'Found custom totp logo' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%<p>My TOTP</p>%, 'Found custom totp label' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%<img src="/static/bootstrap/u2f.png".*?/>%,
        'Found u2f.png' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/u".*?>%,
        'Found 2fregisters/u link' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/totp".*?>%,
        'Found 2fregisters/totp link' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Get U2F register form
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

    # Wait to have two different epoch values
    Time::Fake->offset("+1m");

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
    ok( $data->{result} == 1, 'Key is registered' )
      or explain( $data, '"result":1' );

    # Get 2F register form
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $res->[2]->[0] =~ /2fregistration\.(?:min\.)?js/,
        'Found 2f registration js' );
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/u" class="nodecor">%,
        'Found 2fregisters/u link' )
      or print STDERR Dumper($res);
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/totp" class="nodecor">%,
        'Found 2fregisters/totp link' )
      or print STDERR Dumper($res);

    # Two 2F devices must be registered
    my @sf = map m%<span\s*device=\'(TOTP|U2F)\'\s*epoch=\'\d{10}\'%mg,
      $res->[2]->[0];
    is( scalar @sf, 2, 'Two 2F devices found' );
    ok( $sf[0] eq 'TOTP', 'TOTP device found' ) or print STDERR Dumper( \@sf );
    ok( $sf[1] eq 'U2F',  'U2F device found' )  or print STDERR Dumper( \@sf );
    ok( $res->[2]->[0] =~ qr%<td class="align-middle">myTOTP</td>%,
        'Found TOTP name' )
      or print STDERR Dumper($res);

    # Unregister TOTP
    ok( $res->[2]->[0] =~ m%<span\s*device=\'TOTP\'\s*epoch=\'(\d{10})\'%m,
        "TOTP epoch $1 found" )
      or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res = $client->_post(
            '/2fregisters/totp/delete',
            IO::String->new("epoch=$1"),
            length => 16,
            cookie => "lemonldap=$id",
        ),
        'Delete TOTP query'
    );
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( $data->{result} == 1, 'TOTP is unregistered' )
      or explain( $data, '"result":1' );

    # Get 2F register form
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/u" class="nodecor">%,
        'Found 2fregisters/u link' )
      or print STDERR Dumper($res);
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/totp" class="nodecor">%,
        'Found 2fregisters/totp link' )
      or print STDERR Dumper($res);
    ok( $res->[2]->[0] =~ qr%<span trspan="upgradeSession">%,
        'Found upgradeSession button' )
      or print STDERR Dumper($res);

    # One 2F device must be registered
    @sf = map m%<span\s*device=\'(TOTP|U2F)\'\s*epoch=\'\d{10}\'%mg,
      $res->[2]->[0];
    ok( scalar @sf == 1, 'One 2F device found' )
      or print STDERR Dumper($res);
    ok( $sf[0] eq 'U2F', 'U2F device found' ) or print STDERR Dumper( \@sf );

    # Try to unregister the U2F key
    ok( $res->[2]->[0] =~ m%<span\s*device=\'U2F\'\s*epoch=\'(\d{10})\'%m,
        "U2F epoch $1 found" )
      or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res = $client->_post(
            '/2fregisters/u/delete',
            IO::String->new("epoch=$1"),
            length => 16,
            cookie => "lemonldap=$id",
        ),
        'Delete U2F key query'
    );
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok(
        $data->{error} eq 'notAuthorizedAuthLevel',
        'Not authorized to unregister an U2F key'
    ) or explain( $data, 'Bad result' );

    # Try to upgrade
    # ----------------------
    ok(
        $res = $client->_get(
            '/upgradesession',
            query => 'url='
              . encode_base64( 'http://auth.example.com/2fregisters', '' ),
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Upgrade session query'
    );
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/upgradesession', 'confirm' );

    ok( $res->[2]->[0] =~ /autoRenew\.(?:min\.)?js/, 'Found autoRenew JS' )
      or explain( $res->[2]->[0], 'autoRenew JS not found' );

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
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'upgrading' );
    $query = $query . "&user=dwho&password=dwho";

    ok(
        $res = $client->_post(
            '/upgradesession',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Post login'
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
    $id = expectCookie($res);
    expectSessionAttributes( $client, $id, _2f => "u" );
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );

    # Just U2F device left
    @sf = map m%<span\s*device=\'U2F'\s*epoch=\'\d{10}\'%mg, $res->[2]->[0];
    ok( scalar @sf == 1, 'U2F device found' )
      or print STDERR Dumper($res);

    # Try to unregister the U2F key
    ok( $res->[2]->[0] =~ m%<span\s*device=\'U2F\'\s*epoch=\'(\d{10})\'%m,
        "U2F epoch $1 found" )
      or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res = $client->_post(
            '/2fregisters/u/delete',
            IO::String->new("epoch=$1"),
            length => 16,
            cookie => "lemonldap=$id",
        ),
        'Delete U2F key query'
    );
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( $data->{result} == 1, 'U2F is unregistered' )
      or explain( $data, '"result":1' );

    # Get 2F register form
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $res->[2]->[0] =~ /2fregistration\.(?:min\.)?js/,
        'Found 2f registration js' );
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/u" class="nodecor">%,
        'Found 2fregisters/u link' )
      or print STDERR Dumper($res);
    ok( $res->[2]->[0] =~ qr%<a href="/2fregisters/totp" class="nodecor">%,
        'Found 2fregisters/totp link' )
      or print STDERR Dumper($res);

    # No 2F device left
    @sf = map m%<span device=\'(TOTP|U2F)\' epoch=\'\d{10}\'%g, $res->[2]->[0];
    ok( scalar @sf == 0, 'No 2F device found' )
      or print STDERR Dumper($res);

    $client->logout($id);
}

count($maintests);
clean_sessions();
done_testing( count() );

