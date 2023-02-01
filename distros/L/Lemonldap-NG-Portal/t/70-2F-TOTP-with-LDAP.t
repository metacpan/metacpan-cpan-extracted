use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';
my $maintests = 22;

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }
    eval { require Authen::OATH };
    if ($@) {
        skip 'Authen::OATH is missing', $maintests;
    }
    skip 'LLNGTESTLDAP is not set', $maintests unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';

    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel               => 'error',
                totp2fSelfRegistration => 1,
                restSessionServer      => 1,
                totp2fActivation       => 1,
                totp2fRange            => 2,
                totp2fAuthnLevel       => 5,
                authentication         => 'LDAP',
                userDB                 => 'Same',
                passwordDB             => 'LDAP',
                ldapServer             => $main::slapd_url,
                ldapBase               => 'ou=users,dc=example,dc=com',
                ldapGroupBase          => 'ou=groups,dc=example,dc=com',
                managerDn              => 'cn=admin,dc=example,dc=com',
                managerPassword        => 'admin',
            }
        }
    );
    my $res;

    # Try to authenticate
    # -------------------
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    my ( $host, $url, $query ) =
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
    my $id = expectCookie($res);
    expectRedirection( $res, 'http://auth.example.com/' );

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
    ok( $res->{result} == 1, 'Key is registered' );
    $client->logout($id);

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
    ( $host, $url, $query ) = expectForm( $res, undef, '/totp2fcheck' );

    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
            length => length($query),
        ),
        'Post code'
    );
    $id = expectCookie($res);
    my $attr = getSessionAttributes( $client, $id );
    is( $attr->{_auth}, "LDAP" );
    is( $attr->{_2f},   "totp" );
    is( $attr->{uid},   "dwho" );
    is( $attr->{_dn},   "uid=dwho,ou=users,dc=example,dc=com" );
    is( $attr->{hGroups}->{mygroup}->{name}, "mygroup" );
    $client->logout($id);
}
count($maintests);
clean_sessions();
done_testing( count() );

