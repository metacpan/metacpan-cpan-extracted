# -*- Mode: CPerl -*-

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt"
  or die("could not load $TEST_DIR/common.plt");

plan(test => 49);

# load modules
use Gfsm;

##-- 1: new()
evalok('$fsm=Gfsm::Automaton->new();');

##-- 2--5 : flags
foreach $flag (qw(is_transducer is_weighted is_deterministic sort_mode)) {
  evalok("\$fsm->${flag}(1)==1 && \$fsm->${flag}==1 && \$fsm->${flag}(0)==0 && \$fsm->${flag}==0;");
}
$fsm = Gfsm::Automaton->new(); ##-- reset

##-- 6..8: compile, print, compile+print integrity
evalok("\$fsm->compile('$TEST_DIR/automaton-in.tfst');");
evalok("\$fsm->print_att('$TEST_DIR/automaton-out.tfst');");
ufileok("$TEST_DIR/automaton-in.tfst", "$TEST_DIR/automaton-out.tfst");

##-- 9..10: clone, integrity
evalok('($fsm2=$fsm->clone) && ($fsm2 ne $fsm)');
fsmok("fsm(fsm)===fsm(fsm2)", $fsm,$fsm2);

##-- 11: shadow, null-size
evalok('($fsm2=$fsm->shadow) && $fsm2->n_states==0;');

##-- 12..19 : properties
evalok('$fsm->semiring_type != Gfsm::SRTUnknown');
evalok('$fsm->n_states == 6');
evalok('$fsm->n_final_states==1');
evalok('$fsm->n_arcs==5');
evalok('$fsm->root==0');
evalok('$fsm->root(1)==1 && $fsm->root==1 && $fsm->root(0)==0 && $fsm->root==0');
evalok('$fsm->has_state(5) && !$fsm->has_state(42);');
evalok('!$fsm->is_cyclic();');

##-- 20..26 : state-manipulation
evalok('$fsm->add_state()==6 && $fsm->has_state(6)');
evalok('$fsm->ensure_state(42)==42 && $fsm->has_state(42) && !$fsm->has_state(41)');
evalok('$fsm->remove_state(42); !$fsm->has_state(42)');
evalok('$fsm->is_final(5) && !$fsm->is_final(42) && !$fsm->is_final(0)');
evalok('$fsm->final_weight(5)-1.1 <= 1e-6 && $fsm->final_weight(2,42)-42 <= 1e-6;');
evalok('$fsm0=$fsm->clone; $fsm->renumber_states; 1;');
fsmok("fsm(fsm0)===fsm(fsm)",$fsm0,$fsm);
undef $fsm0;

##-- 27..28 : arc manipluation
evalok('$fsm->add_arc(2,6, 4,3, 0); $fsm->n_states==7 && $fsm->n_arcs==6;');
evalok('$fsm->add_arc(6,1, 0,0, 0); $fsm->is_cyclic==1;');

##-- 29..32 : binary I/O
##   HACK: arc-sort is required for identically ordered arcs after save and reload!
evalok('$fsm->arcsort(Gfsm::ASMLower); $fsm->sort_mode==Gfsm::ASMLower;');
evalok("\$fsm->save('$TEST_DIR/tmp.gfst');");
evalok("(\$fsm2=Gfsm::Automaton->new()) && \$fsm2->load('$TEST_DIR/tmp.gfst');");
fsmok("fsm(fsm)===fsm(fsm2)", $fsm, $fsm2);

##-- 33..49 : arciter
evalok('$ai=Gfsm::ArcIter->new(); !$ai->ok');
evalok('$ai=Gfsm::ArcIter->new($fsm,2); $ai->ok');
evalok('$ai=Gfsm::ArcIter->new($fsm,5); !$ai->ok');
evalok('$ai->open($fsm,1); $ai->ok();');
evalok('$ai->target==2 && $ai->lower==1 && $ai->upper==2 && $ai->weight-2.5 < 1e-6');
evalok('$ai->target(3)==3 && $ai->lower(2)==2 && $ai->upper(1)==1 && $ai->weight(5)-5 < 1e-6');
evalok('$ai->target==3 && $ai->lower==2 && $ai->upper==1 && $ai->weight-5 < 1e-6');
evalok('$n_arcs=$fsm->n_arcs; $ai->remove; $ai->reset; !$ai->ok && $fsm->n_arcs==$n_arcs-1;');
evalok('$ai->open($fsm,3); $ai->ok;');
evalok('$ai->reset; $ai->seek_lower(0);  $ai->ok;');
evalok('$ai->reset; $ai->seek_upper(3);  $ai->ok;');
evalok('$ai->reset; $ai->seek_lower(2); !$ai->ok;');
evalok('$ai->reset; $ai->seek_upper(2); !$ai->ok;');
evalok('$ai->reset; $ai->seek_both(0,3); $ai->ok;');
evalok('$ai->reset; $ai->seek_lower(Gfsm::noLabel); !$ai->ok;');
evalok('$ai->reset; $ai->seek_upper(Gfsm::noLabel); !$ai->ok;');
evalok('$ai->reset; $ai->seek_both(Gfsm::noLabel,Gfsm::noLabel); $ai->ok;');

print "\n";


