use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';
my $maintests = 25;

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }
    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel               => 'error',
                totp2fSelfRegistration => 1,
                totp2fActivation       => 1,
                loginHistoryEnabled    => 1,
                totp2fAuthnLevel       => 8,
                checkUser              => 1,
                authentication         => 'Demo',
                userDB                 => 'Same',
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
    ok( $res->{result} == 1, 'Key is registered' );

    # Try to sign-in
    $client->logout($id);
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho&checkLogins=1'),
            length => 37,
            accept => 'text/html',
        ),
        'Auth query'
    );
    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/totp2fcheck', 'token', 'checkLogins' );
    ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
        'Code' );
    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
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
    ok( @c == 2, 'Two entries found' );

    ok(
        $res = $client->_post(
            '/checkuser',
            IO::String->new($query),
            cookie => "lemonldap=$id",
            length => length($query),
        ),
        'POST checkuser'
    );

    my $data = eval { JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    my @authLevel = map { $_->{key} eq 'authenticationLevel' ? $_ : () }
      @{ $data->{ATTRIBUTES} };
    ok( $authLevel[0]->{value} eq 8, 'Good authenticationLevel found' )
      or explain( $authLevel[0]->{value}, 'authenticationLevel' );

    # Refresh rights (#2179)
    # ------------------------
    ok(
        $res = $client->_get(
            '/refresh',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Refresh query',
    );
    expectRedirection( $res, 'http://auth.example.com/' );

    Time::Fake->offset("+20s");    # Go through handler internal cache

    ok(
        $res = $client->_post(
            '/checkuser',
            IO::String->new($query),
            cookie => "lemonldap=$id",
            length => length($query),
        ),
        'POST checkuser'
    );

    $data = eval { JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( [ $@, $res->[2] ], 'JSON content' );
    @authLevel = map { $_->{key} eq 'authenticationLevel' ? $_ : () }
      @{ $data->{ATTRIBUTES} };
    ok( $authLevel[0]->{value} eq 8, 'Good authenticationLevel found' )
      or explain( $authLevel[0]->{value}, 'authenticationLevel' );

    $client->logout($id);
}
count($maintests);

clean_sessions();

done_testing( count() );

