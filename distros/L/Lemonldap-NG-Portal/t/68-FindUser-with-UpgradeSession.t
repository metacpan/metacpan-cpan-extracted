use Test::More;
use strict;
use JSON;
use IO::String;

require 't/test-lib.pm';

my $maintests = 14;

my $res;
my $json;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                    => 'error',
            authentication              => 'Choice',
            userDB                      => 'Same',
            apacheAuthnLevel            => 5,
            upgradeSession              => 1,
            useSafeJail                 => 1,
            requireToken                => 0,
            findUser                    => 1,
            impersonationRule           => 1,
            findUserControl             => '^[\w*\s]+$',
            findUserWildcard            => '*',
            findUserSearchingAttributes => {
                'uid##1' => 'User',
            },
            authChoiceModules => {
                strong => 'Apache;Demo;Null;;;{}',
                weak   => 'Demo;Demo;Null;;;{}'
            },
            vhostOptions => {
                'test1.example.com' => {
                    vhostAuthnLevel => 3
                },
                locationRules => {
                    'test1.example.com' => {
                        default => 'accept',
                    },
                },
            }
        }
    }
);
use Lemonldap::NG::Portal::Main::Constants 'PE_USERNOTFOUND';

## Simple access
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

my $request = '';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'text/html',
        length => length($request)
    ),
    'Post empty FindUser request'
);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );
( $host, $url, $query ) = expectForm( $res, '#', undef, 'uid' );
ok(
    $res->[2]->[0] =~
m%<input name="spoofId" type="text" class="form-control" value="" autocomplete="off"%,
    'value=""'
) or explain( $res->[2]->[0], 'value=""' );
ok(
    $res->[2]->[0] =~
m%<input id="findUser_uid" name="uid" type="text" autocomplete="off" class="form-control" aria-label="User" placeholder="User" />%,
    'id="findUser_uid"'
) or explain( $res->[2]->[0], 'id="findUser_uid"' );

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&lmAuth=weak'),
        length => 35,
        accept => 'text/html',
    ),
    'Auth query'
);
my $id = expectCookie($res);

# Portal IS NOT a handler
#########################
ok(
    $res = $client->_get(
        '/',
        accept => 'text/html',
        cookie => "lemonldap=$id",
        host   => 'test1.example.com',
    ),
    'GET http://test1.example.com/'
);
expectOK($res);

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
( $host, $url, $query ) =
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
( $host, $url, $query ) = expectForm( $res, '#', undef, 'upgrading', 'url' );

$request = 'uid=rt*';
ok(
    $res = $client->_post(
        '/finduser',
        IO::String->new($request),
        length => length($request),
        cookie => "lemonldap=$id;lemonldappdata=$pdata",
        custom => {
            REMOTE_USER => 'dwho',
        },
    ),
    'Post FindUser request'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 1, ' Good result' )
  or explain( $json, 'result => 1' );
ok( $json->{user} eq 'rtyler', ' Good user' )
  or explain( $json, "user => 'rtyler'" );

# Attempt login
$query = $query . "&spoofId=rtyler&lmAuth=strong";
ok(
    $res = $client->_post(
        '/upgradesession',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
        cookie => "lemonldap=$id;lemonldappdata=$pdata",
        custom => {
            REMOTE_USER => 'dwho',
        },
    ),
    'Post login'
);
$pdata = expectCookie( $res, 'lemonldappdata' );
$id    = expectCookie($res);
expectRedirection( $res, 'http://test1.example.com' );

ok(
    $res = $client->_get(
        '/',
        accept => 'text/html',
        cookie => "lemonldap=$id;lemonldappdata=$pdata",
    ),
    'GET Portal'
);
expectOK($res);
expectAuthenticatedAs( $res, 'rtyler' );

count($maintests);
done_testing( count() );
