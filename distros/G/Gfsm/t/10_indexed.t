# -*- Mode: CPerl -*-

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt"
  or die("could not load $TEST_DIR/common.plt");

plan(test => 22);

# load modules
use Gfsm;
use Gfsm::Automaton::Indexed;

##-- 1: new()
evalok('$xfsm=Gfsm::Automaton::Indexed->new();');

##-- 2--5 : flags
foreach $flag (qw(is_transducer is_weighted is_deterministic sort_mode)) {
  evalok("\$xfsm->${flag}(1)==1 && \$xfsm->${flag}==1 && \$xfsm->${flag}(0)==0 && \$xfsm->${flag}==0;");
}

##-- 6..10: to_automaton(), to_indexed()
use vars qw($fsm);
$fsm = Gfsm::Automaton->new(); ##-- new automaton

evalok("\$fsm->compile('$TEST_DIR/automaton-in.tfst');");
evalok('$xfsm = $fsm->to_indexed();');
evalok('$fsm2 = $xfsm->to_automaton();');
evalok("\$fsm2->print_att('$TEST_DIR/automaton-out.tfst');");
ufileok("$TEST_DIR/automaton-in.tfst", "$TEST_DIR/automaton-out.tfst");

##-- 11..12: clone, integrity
evalok('($xfsm2=$xfsm->clone) && ($xfsm2 ne $xfsm)');
fsmok("fsm(xfsm)===fsm(xfsm2)", $xfsm->to_automaton, $xfsm2->to_automaton);

##-- 13..18 : properties
evalok('$xfsm->semiring_type != Gfsm::SRTUnknown');
evalok('$xfsm->n_states == 6');
evalok('$xfsm->n_arcs==5');
evalok('$xfsm->root==0');
evalok('$xfsm->root(1)==1 && $xfsm->root==1 && $xfsm->root(0)==0 && $xfsm->root==0');
evalok('$xfsm->has_state(5) && !$xfsm->has_state(42);');

##-- 19..22 : binary I/O
##   HACK: arc-sort is required for identically ordered arcs after save and reload!
evalok('$xfsm->arcsort(Gfsm::ASMLower); $xfsm->sort_mode==Gfsm::ASMLower;');
evalok("\$xfsm->save('$TEST_DIR/tmp.gfsx');");
evalok("(\$xfsm2=Gfsm::Automaton::Indexed->new()) && \$xfsm2->load('$TEST_DIR/tmp.gfsx');");
fsmok("fsm(xfsm)===fsm(xfsm2)", $xfsm->to_automaton, $xfsm2->to_automaton);

print "\n";


