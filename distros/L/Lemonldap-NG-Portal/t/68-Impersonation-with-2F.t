use warnings;
use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}
my $maintests = 36;

SKIP: {
    require Lemonldap::NG::Common::TOTP;
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing';
    }
    use_ok('Lemonldap::NG::Common::FormEncode');

    my $res;
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel               => 'error',
                authentication         => 'Demo',
                userDB                 => 'Same',
                portalMainLogo         => 'common/logos/logo_llng_old.png',
                impersonationRule      => 1,
                totp2fSelfRegistration => 1,
                totp2fActivation       => 1,
            }
        }
    );

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/', IO::String->new('user=rtyler&password=rtyler'),
            length => 27
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
    expectAuthenticatedAs( $res, 'rtyler' );
    ok( $res->[2]->[0] =~ m%<span trspan="sfaManager">sfaManager</span>%,
        'sfaManager link found' )
      or print STDERR Dumper( $res->[2]->[0] );

    ## Try to register a TOTP
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
    my ( $key, $token );
    ok( $key   = $res->{secret}, 'Found secret' ) or print STDERR Dumper($res);
    ok( $token = $res->{token},  'Found token' )  or print STDERR Dumper($res);
    ok( $res->{user} eq 'rtyler', 'Found user' )
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

    ## Try to impersonate
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

    $query =~ s/user=/user=rtyler/;
    $query =~ s/password=/password=rtyler/;
    $query =~ s/spoofId=/spoofId=dwho/;

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
    expectAuthenticatedAs( $res, 'dwho' );

    # 2fregisters
    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form 2fregisters'
    );

    ## Try to register a TOTP
    # TOTP form
    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            cookie => "lemonldap=$id",
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
    ok( $res->{error} eq 'notAuthorized', 'Not authorized to register a TOTP' )
      or explain( $res, 'Bad result' );

    # Try to unregister TOTP
    ok(
        $res = $client->_post(
            '/2fregisters/totp/delete',
            IO::String->new("epoch=1234567890"),
            length => 16,
            cookie => "lemonldap=$id",
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
            cookie => "lemonldap=$id",
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Post code'
    );
    eval { $data = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    ok( $data->{error} eq 'notAuthorized', 'Not authorized to verify a TOTP' )
      or explain( $data, 'Bad result' );

    $client->logout($id);
}

count($maintests);
clean_sessions();
done_testing( count() );
