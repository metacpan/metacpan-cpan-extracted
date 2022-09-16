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
    require Lemonldap::NG::Common::TOTP;
    my $res;
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel            => 'error',
                authentication      => 'Demo',
                userDB              => 'Same',
                loginHistoryEnabled => 0,
                brutForceProtection => 0,
                portalMainLogo      => 'common/logos/logo_llng_old.png',
                requireToken        => 0,
                checkUser           => 1,
                impersonationRule   => 1,
                checkUserDisplayPersistentInfo  => 0,
                checkUserDisplayEmptyValues     => 0,
                checkUserDisplayComputedSession => 1,
                impersonationMergeSSOgroups     => 1,
                totp2fSelfRegistration          => 1,
                totp2fActivation                => 1,
                totp2fAuthnLevel                => 8
            }
        }
    );

## Try to authenticate
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

    $query =~ s/user=/user=rtyler/;
    $query =~ s/password=/password=rtyler/;

    #$query =~ s/spoofId=/spoofId=/;
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Auth query'
    );
    count(2);

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
        'Connected as dwho'
    ) or print STDERR Dumper( $res->[2]->[0] );
    expectAuthenticatedAs( $res, 'rtyler' );
    count(2);

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
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );
    count(4);

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

    # Try to sign-in
    $client->logout($id);
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=rtyler&password=rtyler&spoofId=dwho'),
            length => 40,
            accept => 'text/html',
        ),
        'Auth query with Impersonation'
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
    count(4);
    $id = expectCookie($res);

    # CheckUser form
    # ------------------------
    ok(
        $res = $client->_get(
            '/checkuser',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'CheckUser form',
    );
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/checkuser', 'user', 'url' );
    ok( $res->[2]->[0] =~ m%<span trspan="checkUserMerged">%,
        'Found trspan="checkUserMerged"' )
      or explain( $res->[2]->[0], 'trspan="checkUserMerged"' );
    count(2);

    $query =~ s/url=/url=test1.example.com/;

    ok(
        $res = $client->_post(
            '/checkuser',
            IO::String->new($query),
            cookie => "lemonldap=$id",
            length => length($query),
            accept => 'text/html',
        ),
        'POST checkuser'
    );
    count(1);

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/checkuser', 'user', 'url' );
    ok( $res->[2]->[0] =~ m%<span trspan="checkUserMerged">%,
        'Found trspan="checkUserMerged"' )
      or explain( $res->[2]->[0], 'trspan="checkUserMerged"' );
    ok(
        $res->[2]->[0] =~
m%<div class="alert alert-success"><div class="text-center"><b><span trspan="allowed"></span></b></div></div>%,
        'Found trspan="allowed"'
    ) or explain( $res->[2]->[0], 'trspan="allowed"' );
    ok( $res->[2]->[0] =~ m%<span trspan="headers">%, 'Found trspan="headers"' )
      or explain( $res->[2]->[0], 'trspan="headers"' );
    ok( $res->[2]->[0] =~ m%<span trspan="groups_sso">%,
        'Found trspan="groups_sso"' )
      or explain( $res->[2]->[0], 'trspan="groups_sso"' );
    ok( $res->[2]->[0] =~ m%<span trspan="attributes">%,
        'Found trspan="attributes"' )
      or explain( $res->[2]->[0], 'trspan="attributes"' );
    ok( $res->[2]->[0] =~ m%<span trspan="macros">%, 'Found trspan="macros"' )
      or explain( $res->[2]->[0], 'trspan="macros"' );
    ok( $res->[2]->[0] =~ m%<td scope="row">_userDB</td>%, 'Found _userDB' )
      or explain( $res->[2]->[0], 'Attribute Value: _userDB' );
    ok( $res->[2]->[0] =~ m%Auth-User: %, 'Found Auth-User' )
      or explain( $res->[2]->[0], 'Header Key: Auth-User' );
    ok( $res->[2]->[0] =~ m%: dwho<br/>%, 'Found dwho' )
      or explain( $res->[2]->[0], 'Header Value: dwho' );
    ok( $res->[2]->[0] =~ m%<div class="card-text text-left ml-2">su</div>%,
        'Found su' )
      or explain( $res->[2]->[0], 'SSO Groups: su' );
    ok( $res->[2]->[0] =~ m%<td scope="row">uid</td>%, 'Found uid' )
      or explain( $res->[2]->[0], 'Attribute Value uid' );
    ok( $res->[2]->[0] =~ m%<td scope="row">_whatToTrace</td>%,
        'Found _whatToTrace' )
      or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
    count(12);

    ok(
        $res = $client->_get(
            '/checkuser',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'CheckUser form',
    );
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/checkuser', 'user', 'url' );
    ok( $res->[2]->[0] =~ m%<span trspan="checkUserMerged">%,
        'Found trspan="checkUserMerged"' )
      or explain( $res->[2]->[0], 'trspan="checkUserMerged"' );
    count(2);

    $query =~ s/user=dwho/user=rtyler/;

    ok(
        $res = $client->_post(
            '/checkuser',
            IO::String->new($query),
            cookie => "lemonldap=$id",
            length => length($query),
            accept => 'text/html',
        ),
        'POST checkuser'
    );

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/checkuser', 'user', 'url' );
    ok( $res->[2]->[0] =~ m%<span trspan="checkUserComputedSession">%,
        'Found trspan="checkUserComputedSession"' )
      or explain( $res->[2]->[0], 'trspan="checkUserComputedSession"' );
    ok( $res->[2]->[0] =~ m%<td scope="row">authMode</td>%,
        'Found macro authMode' )
      or explain( $res->[2]->[0], 'Macro Key authMode' );
    ok( $res->[2]->[0] =~ m%<td scope="row">TOTP</td>%, 'Found TOTP' )
      or explain( $res->[2]->[0], 'Macro Value TOTP' );
    count(4);

    $client->logout($id);
}
clean_sessions();

done_testing( count() );
