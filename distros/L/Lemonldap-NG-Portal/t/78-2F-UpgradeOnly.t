use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
require 't/smtp.pm';

use_ok('Lemonldap::NG::Common::FormEncode');
count(1);
my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel         => 'error',
            sfOnlyUpgrade    => 1,
            mail2fActivation => '$uid eq "dwho"',
            mail2fCodeRegex  => '\d{4}',
            mail2fAuthnLevel => 5,
            authentication   => 'Demo',
            userDB           => 'Same',
            'vhostOptions'   => {
                'test1.example.com' => {
                    'vhostAuthnLevel' => 3
                },
            },
        }
    }
);

# CASE 1: no 2F available
# -----------------------
my $query = 'user=rtyler&password=rtyler';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
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
    $res = $client->_get(
        '/upgradesession',
        query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29t',
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'Upgrade session query'
);
count(1);

( my $host, my $url, $query ) =
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
count(1);

my $pdata = expectCookie( $res, 'lemonldappdata' );

# A message warns the user that they do not have any 2FA available
expectPortalError( $res, 103 );

# CASE 2: has 2F available
# ------------------------
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
count(1);

$id = expectCookie($res);

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
count(1);

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
count(1);

$pdata = expectCookie( $res, 'lemonldappdata' );

( $host, $url, $query ) =
  expectForm( $res, undef, '/mail2fcheck?skin=bootstrap', 'token', 'code' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code" autocomplete="one-time-code" />%,
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
expectRedirection( $res, 'http://test1.example.com' );
$id = expectCookie($res);

my $cookies = getCookies($res);
ok( !$cookies->{lemonldappdata}, " Make sure no pdata is returned" );
count(1);

clean_sessions();

done_testing( count() );

