use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
my $maintests = 52;

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
                logLevel               => 'error',
                totp2fSelfRegistration => 1,
                totp2fActivation       => 1,
                u2fSelfRegistration    => 1,
                u2fActivation          => 1,
                portalMainLogo         => 'common/logos/logo_llng_old.png',
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
    count(1);

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
    ok( $res->[2]->[0] =~ qr%<img src="/static/bootstrap/totp.png".*?/>%,
        'Found totp.png' )
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
    diag 'Waiting';
    sleep 1;

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
    my @sf = map m%<span device=\'(TOTP|U2F)\' epoch=\'\d{10}\'%g,
      $res->[2]->[0];
    ok( scalar @sf == 2, 'Two 2F devices found' )
      or print STDERR Dumper($res);
    ok( $sf[0] eq 'TOTP', 'TOTP device found' ) or print STDERR Dumper( \@sf );
    ok( $sf[1] eq 'U2F',  'U2F device found' )  or print STDERR Dumper( \@sf );
    ok( $res->[2]->[0] =~ qr%<td class="align-middle">myTOTP</td>%,
        'Found TOTP name' )
      or print STDERR Dumper($res);

    # Unregister TOTP
    ok( $res->[2]->[0] =~ qr%TOTP.*epoch.*(\d{10})%m, "TOTP epoch $1 found" )
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

    # One 2F device must be registered
    @sf = map m%<span device=\'(TOTP|U2F)\' epoch=\'\d{10}\'%g, $res->[2]->[0];
    ok( scalar @sf == 1, 'One 2F device found' )
      or print STDERR Dumper($res);
    ok( $sf[0] eq 'U2F', 'U2F device found' ) or print STDERR Dumper( \@sf );

    # Unregister U2F key
    ok( $res->[2]->[0] =~ qr%U2F.*epoch.*(\d{10})%m, "U2F key epoch $1 found" )
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
    ok( $data->{result} == 1, 'U2F key is unregistered' )
      or explain( $data, '"result":1' );

    # No more 2F device must be registered
    @sf = map m%<span device=\'(TOTP|U2F)\' epoch=\'\d{10}\'%g, $res->[2]->[0];
    ok( scalar @sf == 0, 'No 2F device found' )
      or print STDERR Dumper($res);

    $client->logout($id);
}
count($maintests);

clean_sessions();

done_testing( count() );

