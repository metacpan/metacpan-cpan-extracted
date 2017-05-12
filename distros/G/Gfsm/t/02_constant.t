# -*- Mode: CPerl -*-

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

use Gfsm;

# load common subs
do "$TEST_DIR/common.plt"
  or die("could not load $TEST_DIR/common.plt");

@constants =
  (
   ##--------------------------------------------------------------
   ## Constants: Semiring types
   'SRTUnknown',
   'SRTBoolean',
   'SRTLog',
   'SRTReal',
   'SRTTrivial',
   'SRTTropical',
   'SRTPLog',
   'SRTUser',

   ##--------------------------------------------------------------
   ## Constants: Automaton arc-sort modes
   'ASMNone',
   'ASMLower',
   'ASMUpper',
   'ASMWeight',

   ##--------------------------------------------------------------
   ## Constants: Label sides
   'LSBoth',
   'LSLower',
   'LSUpper',
  );

##-- i..(i+1): test constants
sub constok {
  my $const = shift;
  evalok("defined(Gfsm::${const}) && defined(\$Gfsm::${const}) && Gfsm::${const} eq \$Gfsm::${const}");
}

plan(test => scalar(@constants));

foreach (@constants) {
  constok($_);
}

print "\n";

