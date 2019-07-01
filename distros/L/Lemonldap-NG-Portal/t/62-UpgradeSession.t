use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
require 't/smtp.pm';

use_ok('Lemonldap::NG::Common::FormEncode');
count(1);

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel            => 'error',
            upgradeSession      => 1,
            authentication      => 'Choice',
            apacheAuthnLevel    => 5,
            userDB              => 'Same',
            'authChoiceModules' => {
                'strong' => 'Apache;Demo;Null;;;{}',
                'weak'   => 'Demo;Demo;Null;;;{}'
            },
            'vhostOptions' => {
                'test1.example.com' => {
                    'vhostAuthnLevel' => 3
                },
            },
        }
    }
);

# Try to authenticate
# -------------------
ok(
    my $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&lmAuth=weak'),
        length => 35,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

my $id = expectCookie($res);

# After attempting to access test1,
# the handler sends up back to /upgradesession
# --------------------------------------------

ok(
    my $res = $client->_get(
        '/upgradesession',
        query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29t',
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'Upgrade session query'
);
count(1);

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/upgradesession', 'confirm', 'url' );

# Accept session upgrade
# ----------------------

ok(
    my $res = $client->_post(
        '/upgradesession',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'Accept session upgrade query'
);
count(1);

my $pdata = expectCookie( $res, 'lemonldappdata' );

my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'upgrading', 'url' );

$query = $query . "&lmAuth=strong";

# Attempt login with the "strong" auth choice
# this should trigger 2FA
# -------------------------------------------

ok(
    my $res = $client->_post(
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
count(1);

$pdata = expectCookie( $res, 'lemonldappdata' );
$id = expectCookie($res);

expectRedirection( $res, 'http://test1.example.com' );

# Make pdata was cleared and we aren't being redirected
ok(
    my $res = $client->_get(
        '/',
        accept => 'text/html',
        cookie => "lemonldap=$id;lemonldappdata=$pdata",
    ),
    'Post login'
);
count(1);

expectOK($res);

clean_sessions();

done_testing( count() );

