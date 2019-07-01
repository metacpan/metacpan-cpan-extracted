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
            mail2fActivation    => '$_choice eq "strong"',
            mail2fCodeRegex     => '\d{4}',
            mail2fAuthnLevel    => 5,
            authentication      => 'Choice',
            userDB              => 'Same',
            'authChoiceModules' => {
                'strong' => 'Demo;Demo;Null;;;{}',
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

$query = $query . "&user=dwho&password=dwho&lmAuth=strong";

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
    ),
    'Post login'
);
count(1);

my $pdata = expectCookie( $res, 'lemonldappdata' );

( $host, $url, $query ) =
  expectForm( $res, undef, '/mail2fcheck', 'token', 'code' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" class="form-control" id="extcode" trplaceholder="code" autocomplete="off" />%,
    'Found EXTCODE input'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

ok( mail() =~ m%<b>(\d{4})</b>%, 'Found 2F code in mail' )
  or print STDERR Dumper( mail() );
count(1);

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

