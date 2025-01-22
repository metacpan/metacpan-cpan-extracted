use warnings;
use Test::More;
use strict;
use IO::String;
use JSON qw(to_json from_json);

BEGIN {
    require 't/test-lib.pm';
}
my $maintests = 76;

SKIP: {
    require Lemonldap::NG::Common::TOTP;
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
                contextSwitchingAllowed2fModifications => 1,
                totp2fSelfRegistration                 => 1,
                totp2fActivation                       => 1,
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
            '/2fregisters/totp/getkey',
            IO::String->new(''),
            cookie => "lemonldap=$id",
            length => 0,
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
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
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Post code'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{result} == 1, 'TOTP is registered' );

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
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/totp2fcheck', 'token' );
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

    # 2fregisters
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $res->[2]->[0] =~ /<span id="msg" trspan="choose2f">/,
        'Found choose 2F' )
      or print STDERR Dumper( $res->[2]->[0] );
    my $devices;
    ok(
        $devices =
          $res->[2]->[0] =~
          s%<span\s*device=\'(?:TOTP)\'\s*epoch=\'\d{10}\'%%mg,
        '2F device found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $devices == 1, '2F devices found' )
      or explain( $devices, '2F devices registered' );

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
    ok( $id2 ne $id, 'New SSO session created' )
      or explain( $id2, 'New SSO session created' );

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
    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );

    # JS query
    ok(
        $res = $client->_post(
            '/2fregisters/totp/getkey',
            IO::String->new(''),
            cookie => "lemonldap=$id2",
            length => 0,
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Get new key'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $key   = $res->{secret}, 'Found secret' ) or print STDERR Dumper($res);
    ok( $token = $res->{token},  'Found token' )  or print STDERR Dumper($res);
    ok( $res->{user} eq 'dwho', 'Found user' )
      or print STDERR Dumper($res);
    $key = Convert::Base32::decode_base32($key);

    # Post code
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    ok( $code =~ /^\d{6}$/, 'Code contains 6 digits' );
    $s = "code=$code&token=$token&TOTPName=myTOTP";
    my $epoch = time();
    ok(
        $res = $client->_post(
            '/2fregisters/totp/verify',
            IO::String->new($s),
            length => length($s),
            cookie => "lemonldap=$id2",
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Post code'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{result} == 1, 'TOTP is registered' );

    # 2fregisters
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id2",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $res->[2]->[0] =~ /<span id="msg" trspan="choose2f">/,
        'Found choose 2F' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $devices =
          $res->[2]->[0] =~ s%<span\s*device=\'TOTP\'\s*epoch=\'\d{10}\'%%mg,
        '2F device found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $devices == 1, '2F device found' )
      or explain( $devices, '2F device registered' );

    {
        my $delete_query = buildForm( { epoch => $epoch } );
        $res = $client->_post(
            '/2fregisters/totp/delete',
            $delete_query,
            length => length($delete_query),
            cookie => "lemonldap=$id",
        );
        my $json = expectBadRequest($res);
        ok( $res->[2]->[0] =~ 'csrfError',
            "Deletion expects valid CSRF token" );
    }

    $res = $client->_get(
        '/2fregisters',
        cookie => "lemonldap=$id",
        accept => "test/html",
    );

    # Try to unregister TOTP
    my $delete_query = buildForm( { epoch => $epoch } );
    ok(
        $res = $client->_post(
            '/2fregisters/totp/delete',
            $delete_query,
            length => length($delete_query),
            cookie => "lemonldap=$id2",
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Delete TOTP query'
    );
    my $data;
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( $data->{result} == 1, 'TOTP removed' )
      or explain( $data, '"result":1' );

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
    ok( $id2 ne $id, 'New SSO session created' )
      or explain( $id2, 'New SSO session created' );

    # 2fregisters
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id2",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $res->[2]->[0] =~ /<span id="msg" trspan="choose2f">/,
        'Found choose 2F' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%<span\s*device=\'TOTP\'\s*epoch=\'(\d{10})\'%m,
        'TOTP found' )
      or print STDERR Dumper( $res->[2]->[0] );
    $epoch = $1;
    ok(
        $devices =
          $res->[2]->[0] =~
          s%<span\s*device=\'(?:TOTP)\'\s*epoch=\'(?:\d{10})\'%%mg,
        '2F devices found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $devices == 1, '2F devices registered' )
      or explain( $devices, '2F devices registered' );

    # Try to unregister TOTP
    $delete_query = buildForm( { epoch => $epoch } );
    ok(
        $res = $client->_post(
            '/2fregisters/totp/delete',
            $delete_query,
            length => length($delete_query),
            cookie => "lemonldap=$id2",
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Delete TOTP query'
    );
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( $data->{result} == 1, '2F removed' )
      or explain( $data, '"result":1' );

    # 2fregisters
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id2",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );
    ok( $devices == 1, '2F device registered' )
      or explain( $devices, '2F device registered' );

    $client->logout($id);
    $client->logout($id2);
}

count($maintests);

clean_sessions();
done_testing( count() );
