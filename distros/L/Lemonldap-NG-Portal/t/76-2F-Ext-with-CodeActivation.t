use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';

use_ok('Lemonldap::NG::Common::FormEncode');
count(1);

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel            => 'error',
            ext2fActivation     => 1,
            ext2fCodeActivation => 'A1b2C0',
            ext2FSendCommand    => 't/sendCode.pl -uid $uid -code $code',
            authentication      => 'Demo',
            userDB              => 'Same',
        }
    }
);

my $res;

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/ext2fcheck?skin=bootstrap', 'token', 'code' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code" autocomplete="one-time-code" />%,
    'Found EXTCODE input'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

$query =~ s/code=/code=A1b2C0/;
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
$client->logout($id);

clean_sessions();

done_testing( count() );

