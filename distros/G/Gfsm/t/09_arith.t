# -*- Mode: CPerl -*-

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt"
  or die("could not load $TEST_DIR/common.plt");

plan(test => 1);

# load modules
#use Gfsm;

##--------------------------------------------------------------
## Automaton arithmetic

##... TODO
skip('Skip until tests are written', 1);

print "\n";


