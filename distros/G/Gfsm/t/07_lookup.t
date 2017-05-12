# -*- Mode: CPerl -*-

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt"
  or die("could not load $TEST_DIR/common.plt");

plan(test => 10);

# load modules
use Gfsm;

##--------------------------------------------------------------
## Full Lookup

use vars qw($lkp $res123 $res223);

# 1..2: new, compile
evalok('$lkp = Gfsm::Automaton->new();');
evalok('$lkp->compile("$TEST_DIR/lookup.tfst");');
$lkp->arcsort(Gfsm::ASMLower); ##-- for strict result-automaton identity

# 3..4 : lookup path '1 2 3'
evalok('$res123 = $lkp->lookup([1,2,3]);');
fsmfileok($res123,'lookup-123-out.tfst');

# 5..6 : lookup path '2 2 3'
evalok('$res223 = $lkp->lookup([2,2,3]);');
fsmfileok($res223,'lookup-223-out.tfst');

##-- TODO: lookup_full

##--------------------------------------------------------------
## Paths

sub path2str {
  my $path = shift;
  return ('{'
	  .join(' ', @{$path->{lo}})
	  .' : '
	  . join(' ', @{$path->{hi}})
	  .' <' . int($path->{w}+.5) . '>'
	  .'}'
	 );
}
sub paths2str { return join(",", map { path2str($_) } @{$_[0]}); }

##-- 7..8: paths(1,2,3)
evalok('$paths123 = $res123->paths();');
evalok('paths2str($paths123) eq "{1 2 3 : 2 3 1 <3>}"');

##-- 9..10: paths(2,2,3)
evalok('$paths223 = $res223->paths();');
evalok('paths2str($paths223) eq "{2 2 3 : 2 2 3 <0>},{2 2 3 : 3 3 1 <3>}"');


print "\n";


