use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 2;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );


use Getopt::LL qw(getoptions);

my $argv = [qw( -jumps over -X --the lazy --oops -dawg 10 the -f myfile.txt --quick brown fox)];


my $rules = {
    '--oops'    => 'NONEXISTING',
};
my $getopt_options = {
   die_on_type_mismatch => 0,
   silent               => 0,
   allow_unspecified    => 1,
};

my $result = do { eval 'getoptions($rules, $getopt_options, $argv)' };
ok(!$result, 'bail on nonexistent rule type');
like( $EVAL_ERROR,
    qr/Unknown rule type \[NONEXISTING\] for argument \[--oops\]/,
    'croak on nonexistent rule type'
);
