# -*- Mode: Perl -*-
# t/06_ops.t - type-operations: subsumes(), extends(), lub(), glb()


$TEST_DIR = './t';
#use lib qw(../blib/lib); $TEST_DIR = '.'; # for debugging

use Math::PartialOrder qw(:typevars);

# load common subs
do "$TEST_DIR/common.plt";

$n = scalar(@classes);
plan(test => (20*$n));

# test user-defined stuff
package aa1;
use vars qw(*lub *glb);
sub subumes { return $_[1] =~ /^\d+$/; }
sub hookme { return "$_[0]:$_[1]"; }
*lub = \&hookme;
*glb = \&hookme;

package main;
sub mysubsumes { return $_[1] =~ /^\d+$/; }
sub mybounds { return "$_[0]:$_[1]"; }

# load and test subclasses (? subtests)
foreach (@classes) {
  $class = "Math::PartialOrder::$_";
  print "Test $class\n";
  $h = testhi($class);

  isok('subsumes [undef]', # ok=i+1
       $h->subsumes(undef,'root') && !$h->subsumes('root',undef));
  isok('subsumes [equal]', # ok=i+2
       $h->subsumes('a','a'));
  isok('subsumes [top]', # ok=i+3
       $h->subsumes('a',$TYPE_TOP) && !$h->subsumes($TYPE_TOP,'a'));
  isok('subsumes [oo-hook]', # ok=i+4
       $h->subsumes('aa1', 42) && !$h->subsumes('aa1','nope'));
  isok('subsumes [fcn-hook]', # ok=i+5
       $h->subsumes(\&mysubsumes,42) && !$h->subsumes(\&mysubsumes,'nope'));
  isok('subsumes [lookup]', # ok=i+6
       $h->subsumes('a','c') && !$h->subsumes('c','a'));

  isok('lub [undef]', $h->lub(undef,'a'), 'a'); # ok=i+7
  isok('lub [equal]', $h->lub('a','a'), 'a'); # ok=i+8
  isok('lub [top]', $h->lub(42,$TYPE_TOP), $TYPE_TOP); # ok=i+9
  isok('lub [oo-hook]', $h->lub('aa1',42), 'aa1:42'); # ok=i+10
  isok('lub [fcn-hook]', $h->lub(\&mybounds,42), 'lub:42'); # ok=i+11
  isok('lub [positive-lookup]', $h->lub('a','b'), 'c'); # ok=i+12
  isok('lub [negative-lookup]', !$h->lub('aa1','bb')); # ok=i+13

  isok('glb [undef]', $h->glb(undef,'a'), undef); # ok=i+14
  isok('glb [equal]', $h->glb('a','a'), 'a'); # ok=i+15
  isok('glb [top]', $h->glb(42,$TYPE_TOP), 42); # ok=i+16
  isok('glb [oo-hook]', $h->glb('aa1',42), 'aa1:42'); # ok=i+17
  isok('glb [fcn-hook]', $h->glb(\&mybounds,42), 'glb:42'); # ok=i+18
  isok('glb [positive-lookup]', $h->glb('c','aa1'), 'a'); # ok=i+19
  isok('glb [negative-lookup]', !$h->glb('nope','either')); # ok=i+20
}

# end of t/06_ops.t

