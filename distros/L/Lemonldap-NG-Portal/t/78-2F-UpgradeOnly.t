use warnings;
use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
require 't/smtp.pm';

use_ok('Lemonldap::NG::Common::FormEncode');
my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel               => 'error',
            sfOnlyUpgrade          => 1,
            sfRequired             => '$uid eq "msmith"',
            totp2fActivation       => '$uid eq "msmith" and has2f("TOTP")',
            totp2fSelfRegistration => '1',
            totp2fAuthnLevel       => 5,
            mail2fActivation       => '$uid eq "dwho"',
            mail2fCodeRegex        => '\d{4}',
            mail2fAuthnLevel       => 5,
            authentication         => 'Demo',
            userDB                 => 'Same',
            'vhostOptions'         => {
                'test1.example.com' => {
                    'vhostAuthnLevel' => 3
                },
            },
        }
    }
);

subtest "No 2FA available during upgrade" => sub {
    ok(
        $res = $client->_post(
            '/',
            { user => 'rtyler', password => 'rtyler' },
            accept => 'text/html',
        ),
        'Auth query'
    );

    my $id = expectCookie($res);

    # After attempting to access test1,
    # the handler sends up back to /upgradesession
    # --------------------------------------------

    ok(
        $res = $client->_get(
            '/upgradesession',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29t',
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Upgrade session query'
    );

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/upgradesession', 'confirm', 'url' );

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

    my $pdata = expectCookie( $res, 'lemonldappdata' );

    # A message warns the user that they do not have any 2FA available
    expectPortalError( $res, 103 );
};

subtest "upgrade with available 2fa" => sub {
    ok(
        my $res = $client->_post(
            '/',
            { user => "dwho", password => "dwho" },
            accept => 'text/html',
        ),
        'Auth query'
    );

    my $id = expectCookie($res);

    # After attempting to access test1,
    # the handler sends up back to /upgradesession
    # --------------------------------------------

    ok(
        $res = $client->_get(
            '/upgradesession',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29t',
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Upgrade session query'
    );

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/upgradesession', 'confirm', 'url' );

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

    my $pdata = expectCookie( $res, 'lemonldappdata' );

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/mail2fcheck?skin=bootstrap', 'token', 'code' );

    ok(
        $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code"%,
        'Found EXTCODE input'
    ) or print STDERR Dumper( $res->[2]->[0] );

    ok( mail() =~ m%<b>(\d{4})</b>%, 'Found 2F code in mail' )
      or print STDERR Dumper( mail() );

    my $code = $1;

    # Post 2F code
    # ------------

    $query =~ s/code=/code=${code}/;
    ok(
        $res = $client->_post(
            '/mail2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "lemonldap=$id;lemonldappdata=$pdata",
        ),
        'Post code'
    );
    expectRedirection( $res, 'http://test1.example.com' );
    $id = expectCookie($res);

    my $cookies = getCookies($res);
    ok( !$cookies->{lemonldappdata}, " Make sure no pdata is returned" );

    is( getSession($id)->data->{authenticationLevel}, 5,
        "Expected authnlevel" );
};

subtest "upgrade and register 2fa" => sub {
    ok(
        my $res = $client->_post(
            '/',
            { user => "msmith", password => "msmith" },
            accept => 'text/html',
        ),
        'Auth query'
    );

    my $id = expectCookie($res);
    is( getSession($id)->data->{authenticationLevel}, 1,
        "Expected authnlevel" );

    # After attempting to access test1,
    # the handler sends up back to /upgradesession
    # --------------------------------------------

    ok(
        $res = $client->_get(
            '/upgradesession',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29t',
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Upgrade session query'
    );

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/upgradesession', 'confirm', 'url' );

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

    my $pdata = expectCookie( $res, 'lemonldappdata' );

    expectRedirection( $res, 'http://auth.example.com/2fregisters' );
    ok(
        $res = $client->_get(
            '/2fregisters',
            accept => 'text/html',
            cookie => "lemonldap=$id; lemonldappdata=$pdata",
        ),
        'Move to 2FA list'
    );
    like( $res->[2]->[0],
        qr/trspan="2fRegRequired"/, "Found registration required prompt" );
    like( $res->[2]->[0],
        qr(href="/2fregisters/totp"), "Found link to TOTP registration" );

    ok(
        $res = $client->_get(
            '/2fregisters/totp',
            accept => 'text/html',
            cookie => "lemonldap=$id; lemonldappdata=$pdata",
        ),
        'On TOTP registration page'
    );

    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );

    # JS query
    ok(
        $res = $client->_post(
            '/2fregisters/totp/getkey',
            IO::String->new(''),
            cookie => "lemonldap=$id; lemonldappdata=$pdata",
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
    is( $res->{user}, 'msmith', 'Found user' );
    $key = Convert::Base32::decode_base32($key);

    # Post code
    ok( my $code = getTotp($key), 'Code' );
    ok( $code =~ /^\d{6}$/,       'Code contains 6 digits' );
    ok(
        $res = $client->_post(
            '/2fregisters/totp/verify',
            {
                code     => $code,
                token    => $token,
                TOTPName => "mytotp",
            },
            cookie => "lemonldap=$id; lemonldappdata=$pdata",
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

    # JS sends us to ?continue=1
    ok(
        $res = $client->_get(
            '/2fregisters',
            query  => "continue=1",
            accept => 'text/html',
            cookie => "lemonldap=$id; lemonldappdata=$pdata",
        ),
        'Continue registration'
    );

    expectRedirection( $res, 'http://test1.example.com' );
    $id = expectCookie($res);

    my $cookies = getCookies($res);
    ok( !$cookies->{lemonldappdata}, " Make sure no pdata is returned" );

    is( getSession($id)->data->{authenticationLevel}, 5,
        "Expected authnlevel" );
};

clean_sessions();

done_testing();

