use Test::More;
use strict;
use IO::String;
use JSON qw(to_json from_json);

require 't/test-lib.pm';
my $maintests = 27;

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }
    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel               => 'error',
                checkUser              => 1,
                sfOnlyUpgrade          => 1,
                totp2fSelfRegistration => 1,
                totp2fActivation       => 1,
                totp2fAuthnLevel       => 3,
                totp2fIssuer           => 'LLNG_Demo',
                authentication         => 'Demo',
                userDB                 => 'Same',
            }
        }
    );
    my ( $res, $host, $url, $query, $id );

    # Try to authenticate
    # -------------------
    $query = 'user=dwho&password=dwho';
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

    # Check authLevel (Demo -> 1)
    ok(
        $res = $client->_get(
            '/checkuser', cookie => "lemonldap=$id",
        ),
        'CheckUser',
    );
    ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    my @authLevel = map { $_->{key} eq 'authenticationLevel' ? $_ : () }
      @{ $res->{ATTRIBUTES} };
    ok( $authLevel[0]->{value} == 1, 'AuthenticationLevel == 1' )
      or explain( $authLevel[0]->{value}, 'AuthenticationLevel value == 1' );

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
    ok( $key   = $res->{secret}, 'Found secret' ) or print STDERR Dumper($res);
    ok( $token = $res->{token},  'Found token' )  or print STDERR Dumper($res);
    ok( $res->{portal} eq 'LLNG_Demo', 'Found issuer' )
      or print STDERR Dumper($res);
    ok( $res->{user} eq 'dwho', 'Found user' )
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
        ),
        'Post code'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{result} == 1, 'TOTP is registered' );

    ok(
        $res = $client->_get(
            '/2fregisters',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Form registration'
    );
    ok(
        $res->[2]->[0] =~
qr%<a href="http://auth.example.com/upgradesession\?forceUpgrade=1&url=aHR0cDovL2F1%,
        'Found forceUpgrade flag'
    ) or explain( $res->[2]->[0], 'forceUpgrade flag' );

    # Try to upgrade from 2fManager
    ok(
        $res = $client->_get(
            '/upgradesession',
            query =>
'forceUpgrade=1&url=aHR0cDovL2F1dGguZXhhbXBsZS5jb20vMmZyZWdpc3RlcnM=',
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Upgrade session query from 2fManager'
    );

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/upgradesession', 'confirm', 'url',
        'forceUpgrade' );

    # Accept session upgrade
    # ----------------------
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

    # POST TOTP
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

    # Check authLevel (TOTP -> 3)
    ok(
        $res = $client->_get(
            '/checkuser', cookie => "lemonldap=$id",
        ),
        'CheckUser',
    );
    ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    @authLevel = map { $_->{key} eq 'authenticationLevel' ? $_ : () }
      @{ $res->{ATTRIBUTES} };
    ok( $authLevel[0]->{value} == 3, 'AuthenticationLevel == 3' )
      or explain( $authLevel[0]->{value}, 'AuthenticationLevel value == 3' );
}
count($maintests);

clean_sessions();

done_testing( count() );

