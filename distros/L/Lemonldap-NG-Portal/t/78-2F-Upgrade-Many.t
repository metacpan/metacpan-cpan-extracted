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
            logLevel             => 'error',
            upgradeSession       => 1,
            mail2fActivation     => '$_choice eq "strong"',
            mail2fCodeRegex      => '\d{4}',
            mail2fAuthnLevel     => 5,
            ext2fActivation      => '$_choice eq "strong"',
            ext2fCodeActivation  => 0,
            ext2FSendCommand     => 't/sendOTP.pl -uid $uid',
            ext2FValidateCommand => 't/vrfyOTP.pl -uid $uid -code $code',
            authentication       => 'Choice',
            userDB               => 'Same',
            'authChoiceModules'  => {
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
    $res = $client->_post(
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
ok( $res->[2]->[0] =~ qq%<img src="/static/common/logos/logo_llng_400px.png"%,
    'Found custom Main Logo' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%<span id="languages"></span>%, ' Language icons found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

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

( $host, $url, $query ) = expectForm( $res, '#', undef, 'upgrading', 'url' );

$query = $query . "&user=dwho&password=dwho&lmAuth=strong";

# Attempt login with the "strong" auth choice
# this should trigger 2FA
# -------------------------------------------

ok(
    $res = $client->_post(
        '/upgradesession',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
        cookie => "lemonldap=$id;lemonldappdata=$pdata",
    ),
    'Post login'
);
count(1);

$pdata = expectCookie( $res, 'lemonldappdata' );

( $host, $url, $query ) =
  expectForm( $res, undef, '/2fchoice', 'token', 'checkLogins' );

ok(
    $res->[2]->[0] =~
qq%<button type="submit" name="sf" value="mail" class="mx-3 btn btn-light" role="button">%,
    'Found mail'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

$query .= '&sf=mail';
ok(
    $res = $client->_post(
        '/2fchoice',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
        cookie => "lemonldap=$id;lemonldappdata=$pdata",
    ),
    'Post ext2f choice'
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

