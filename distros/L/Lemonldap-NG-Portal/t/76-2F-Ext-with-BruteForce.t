use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';

use_ok('Lemonldap::NG::Common::FormEncode');
count(1);

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                  => 'error',
            ext2fActivation           => 1,
            ext2fCodeActivation       => 0,
            ext2FSendCommand          => 't/sendOTP.pl -uid $uid',
            ext2FValidateCommand      => 't/vrfyOTP.pl -uid $uid -code $code',
            authentication            => 'Demo',
            userDB                    => 'Same',
            loginHistoryEnabled       => 1,
            bruteForceProtection      => 1,
            bruteForceProtectionTempo => 5,
        }
    }
);

my $res;

## First failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23
    ),
    '1st Bad Auth query'
);
count(1);
expectReject($res);

## Second failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23
    ),
    '2nd Bad Auth query'
);
count(1);
expectReject($res);

## Third failed connection
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23
    ),
    '3rd Bad Auth query'
);
count(1);
expectReject($res);

## Forth failed connection -> rejected
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=ohwd'),
        length => 23,
        accept => 'text/html',
    ),
    '4th Bad Auth query -> Rejected'
);
count(1);
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/, 'Protection enabled' );
count(1);

diag 'Waiting';
sleep 2;

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&checkLogins=1'),
        length => 37,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/ext2fcheck', 'token', 'code', 'checkLogins' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" class="form-control" id="extcode" trplaceholder="code" autocomplete="off" />%,
    'Found EXTCODE input'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

$query =~ s/code=/code=123456/;
ok(
    $res = $client->_post(
        '/ext2fcheck',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Post code'
);
count(1);

ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/, 'Protection enabled' );
count(1);

diag 'Waiting';
sleep 4;

# Try to authenticate again
# -------------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&checkLogins=1'),
        length => 37,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

( $host, $url, $query ) =
  expectForm( $res, undef, '/ext2fcheck', 'token', 'code', 'checkLogins' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" class="form-control" id="extcode" trplaceholder="code" autocomplete="off" />%,
    'Found EXTCODE input'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

$query =~ s/code=/code=123456/;
ok(
    $res = $client->_post(
        '/ext2fcheck',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Post code'
);
count(1);

my $id = expectCookie($res);

ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);
my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
ok( @c == 5, 'Five entries found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

$client->logout($id);
clean_sessions();

done_testing( count() );

