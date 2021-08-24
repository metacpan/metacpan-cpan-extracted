use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
my $maintests = 10;

use_ok('Lemonldap::NG::Common::FormEncode');

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel             => 'error',
            rest2fActivation     => 1,
            rest2fInitUrl        => 'http://auth.example.com/init',
            rest2fInitArgs       => { name => 'uid' },
            rest2fVerifyUrl      => 'http://auth.example.com/vrfy',
            rest2fVerifyArgs     => { code => 'code' },
            rest2fLogo           => 'u2f.png',
            totp2fActivation     => '$uid eq "dwho"',
            ext2fActivation      => 1,
            ext2fCodeActivation  => 0,
            ext2FSendCommand     => 't/sendOTP.pl -uid $uid',
            ext2FValidateCommand => 't/vrfyOTP.pl -uid $uid -code $code',
            ext2fLogo            => 'yubikey.png',
            loginHistoryEnabled  => 1,
            authentication       => 'Demo',
            userDB               => 'Same',
        }
    }
);

my $res;

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

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/2fchoice', 'token', 'checkLogins' );

ok(
    $res->[2]->[0] =~
      qq%<img src="/static/bootstrap/u2f.png" alt="rest2F" title="rest2F" />%,
    'Found u2f.png'
) or print STDERR Dumper( $res->[2]->[0] );

ok(
    $res->[2]->[0] =~
      qq%<img src="/static/bootstrap/yubikey.png" alt="ext2F" title="ext2F" />%,
    'Found yubikey.png'
) or print STDERR Dumper( $res->[2]->[0] );

ok(
    $res->[2]->[0] =~
      qq%<img src="/static/bootstrap/totp.png" alt="totp2F" title="totp2F" />%,
    'Found totp.png'
) or print STDERR Dumper( $res->[2]->[0] );

$query .= '&sf=ext';
ok(
    $res = $client->_post(
        '/2fchoice',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Post ext2f choice'
);

( $host, $url, $query ) =
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

my $id = expectCookie($res);

ok( $res->[2]->[0] =~ /trspan="lastLogins"/, 'History found' )
  or print STDERR Dumper( $res->[2]->[0] );
my @c = ( $res->[2]->[0] =~ /<td>127.0.0.1/gs );
ok( @c == 1, 'One entry found' );

$client->logout($id);

count($maintests);

clean_sessions();

done_testing( count() );

