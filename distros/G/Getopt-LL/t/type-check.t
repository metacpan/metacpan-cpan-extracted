use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 5;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );


use Getopt::LL qw(getoptions);

my $argv = [qw( --number notANumber --hex 0xfeedface --not-hex 0xf12XX )];


my $rules = {
    '--number' => 'digit',
};
my $getopt_options = {
   die_on_type_mismatch => 1,
   allow_unspecified    => 1,
   silent               => 0,
};
my $result = do { eval 'getoptions($rules, $getopt_options, $argv)' };
ok(!$result, 'type-check number');
like( $EVAL_ERROR, qr/--number must be a digit/, 'croak on type mismatch' );

$rules = {
    '--hex' => 'digit',
};
$result = getoptions($rules, $getopt_options, $argv);
is($result->{'--hex'}, '4277009102', 'type-check: hex is converted to decimal');

$rules = {
    '--not-hex' => 'digit',
};
$getopt_options = {
   die_on_type_mismatch => 1,
   allow_unspecified    => 1,
   silent               => 1,
};
 $result = do { eval 'getoptions($rules, $getopt_options, $argv)' };
ok(!$result, 'type-check number');
like( $EVAL_ERROR, qr/--not-hex must be a digit/, 'croak on type mismatch' );

my $getopt = Getopt::LL->new({});
eval '$getopt->_warn("_warn seems to work fine :-)");'

