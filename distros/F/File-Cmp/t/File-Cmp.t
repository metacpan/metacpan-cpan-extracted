#!perl
use strict;
use warnings;
use Test2::V0;    # plan is down near bottom
use File::Cmp 'fcmp';

like dies { fcmp() }, qr/needs two files/;

like dies { fcmp(qw{t/nope1 t/nope2 sizecheck 0}) }, qr/could not open/;

like dies { fcmp( qw{t/nope1 t/nope2}, fscheck => 1 ) }, qr/could not stat/;

my $reason;       # for reason => callback to know what check triggered diff

# NOTE the [] is for test coverage and is in no way advised
ok( fcmp( 'MANIFEST', 'MANIFEST', [] ), 'manifestly the same' );
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
ok( !fcmp( 'this', 'that', { reason => \$reason } ), 'extra line, sizecheck' );
is( $reason, 'size', 'reason callback' );

my @where;
ok( !fcmp(
        'this', 'that',
        sizecheck => 0,
        reason    => \$reason,
        tells     => \@where,
    ),
    'extra line, no sizecheck'
);
is( $reason, 'eof',    'reason callback' );
is( \@where, [ 5, 5 ], 'william tells' );

ok( !fcmp( qw/this that/, RS => \4096 ) );

# 'tells' should disable the -s check, so must paw through file
# contents. NOTE that this test will fail if MANIFEST or the top of this
# file are fiddled with, sorry about that.
seek DATA, 0, 0;
ok( !fcmp(
        'MANIFEST', \*DATA,
        binmode => ':raw',
        reason  => \$reason,
        tells   => \@where
    ),
    'differ'
);
is( $reason, 'diff',   'reason callback' );
is( \@where, [ 9, 7 ], 'william tells' );

# mostly for test coverage.
ok( fcmp(qw/MANIFEST MANIFEST fscheck 1/) );
ok( !fcmp(qw/MANIFEST Changes fscheck 1/) );

# TODO a better way to make binmode fail might be nice :/
like dies { fcmp( 'MANIFEST', 'Changes', binmode => [], sizecheck => 0 ) },
  qr/binmode failed/;

# XXX sparse files might be good to test, but would likely have to
# generate such files, assuming the target system supports them, etc.

done_testing 19;

__DATA__
An, Android
