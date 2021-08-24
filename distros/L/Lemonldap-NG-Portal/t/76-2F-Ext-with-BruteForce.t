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
ok( $res->[2]->[0] =~ /<span trmsg="86">/, 'Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

# Count down
Time::Fake->offset("+2s");

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
ok( $res->[2]->[0] =~ /<span trmsg="86"><\/span>/,
    'Rejected -> Protection enabled' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%(\d) <span trspan="seconds">seconds</span>%,
    "LockTime = $1" );
ok( $1 < 5 && $1 >= 2, 'LockTime in range' )
  or print STDERR Dumper( $res->[2]->[0] );
count(4);

# Cool down
Time::Fake->offset("+6s");

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

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/ext2fcheck?skin=bootstrap', 'token', 'code',
    'checkLogins' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code" autocomplete="one-time-code" />%,
    'Found EXTCODE input'
) or print STDERR Dumper( $res->[2]->[0] );

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
count(2);
my $id = expectCookie($res);

ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
  or print STDERR Dumper( $res->[2]->[0] );
my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
ok( @c == 4, 'Four entries found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

$client->logout($id);
clean_sessions();

done_testing( count() );

