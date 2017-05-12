use strict;
use warnings;
use Test::More;

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 7;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );

BEGIN {
@ARGV = qw( The --quick 10 brown fox -jumps over --the lazy -dawg );
}

use Getopt::LL::Simple qw(
    --quick=d
    -jumps=s
    --the=s
    -dawg
);

is( $ARGV{'--quick'}, 10,     '--quick = 10'   );
is( $ARGV{'-jumps'},  'over', '-jumps  = over' );
is( $ARGV{'--the'},   'lazy', '--the  = lazy'  );
is( $ARGV{'-dawg'},   1,      '-dawg  = 1'     );

is( $ARGV[0], 'The',      'rest[0] == The'    );
is( $ARGV[1], 'brown',    'rest[1] == brown'  );
is( $ARGV[2], 'fox',      'rest[2] == fox'    );
