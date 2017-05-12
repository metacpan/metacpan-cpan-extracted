use strict;
use warnings;
use Test::More;

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 5;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );

BEGIN {
    @ARGV = qw( The --quick 10 brown fox -jumps over --the lazy -dawg );
}

use Getopt::LL::Simple;

is($ARGV{'--quick'}, 1, 'default ruletype for --quick is flag');
is($ARGV{'-jumps'}, 1, 'default ruletype for --jumps is flag');
is($ARGV{'--the'}, 1, 'default ruletype for --the is flag');
is($ARGV{'-dawg'}, 1, 'default ruletype for -dawg is flag');

is_deeply([@ARGV], [qw(The 10 brown fox over lazy)],
    'the rest is kept in @ARGV'
);
