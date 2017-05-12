#!perl

use strict;
use warnings;

use Test::More;    # plan is down near bottom

BEGIN { use_ok( 'File::Cmp', qw/fcmp/ ) }

my $reason;        # for reason => callback to know what check triggered diff

ok( fcmp( 'MANIFEST', 'MANIFEST' ), 'manifestly the same' );
ok( !fcmp( 'MANIFEST', \*DATA, reason => \$reason ), 'differ' );
is( $reason, 'size', 'reason callback' );

# seek() to reset should not be necessary, as the 'fscheck' code should
# stat this file, discover that both filehandle reference point to this
# file, and avoid looking at the contents.
#seek DATA, 0, 0;
ok( fcmp( \*DATA, \*DATA, fscheck => 1, reason => \$reason ), 'fscheck' );
is( $reason, 'fscheck', 'reason callback' );

# Default line-based reads are actually tricker than just setting RS to
# something - RS => \"4096" or whatever and binmode => ':raw' might
# actually be better defaults to set...
ok( !fcmp( 'this', 'that', reason => \$reason ), 'extra line, sizecheck' );
is( $reason, 'size', 'reason callback' );

my @where;
ok(
  !fcmp(
    'this', 'that',
    sizecheck => 0,
    reason    => \$reason,
    tells     => \@where
  ),
  'extra line, no sizecheck'
);
is( $reason, 'eof', 'reason callback' );
is_deeply( \@where, [ 5, 5 ], 'william tells' );

# 'tells' should disable the -s check, so must paw through file
# contents. NOTE that this test will fail if MANIFEST or the top of this
# file are fiddled with, sorry about that.
seek DATA, 0, 0;
ok(
  !fcmp(
    'MANIFEST', \*DATA,
    binmode => ':raw',
    reason  => \$reason,
    tells   => \@where
  ),
  'differ'
);
is( $reason, 'diff', 'reason callback' );
is_deeply( \@where, [ 8, 7 ], 'william tells' );

# XXX sparse files might be good to test, but would likely have to
# generate such files, assuming the target system supports them, etc.

plan tests => 14;

__DATA__
An, Android
