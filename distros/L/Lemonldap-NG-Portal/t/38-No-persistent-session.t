use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';
my $maintests = 18;

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }
    eval { require Authen::OATH };
    if ($@) {
        skip 'Authen::OATH is missing', $maintests;
    }
    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                 => 'error',
                totp2fSelfRegistration   => 1,
                totp2fActivation         => 1,
                totp2fDigits             => 8,
                totp2fTTL                => -1,
                loginHistoryEnabled      => 1,
                disablePersistentStorage => 1,
            }
        }
    );
    my $res;

    # Try to authenticate 1
    # ---------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    my $id = expectCookie($res);
    $client->logout($id);

    # Try to authenticate 2
    # ---------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    $id = expectCookie($res);
    $client->logout($id);

    # Try to authenticate 3
    # ---------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho&checkLogins=1'),
            length => 37,
            accept => 'text/html',
        ),
        'Auth query'
    );
    $id = expectCookie($res);

    ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
      or print STDERR Dumper( $res->[2]->[0] );
    my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
    ok( @c == 1, ' -> NO history : only one entry found' );

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
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 8 ),
        'Code' );
    ok( $code =~ /^\d{8}$/, 'Code contains 8 digits' );
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

    # NO 2FA stored
    $id = expectCookie($res);
    $client->logout($id);
}
count($maintests);

clean_sessions();

done_testing( count() );

