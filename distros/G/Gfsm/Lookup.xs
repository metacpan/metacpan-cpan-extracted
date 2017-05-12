#/*-*- Mode: C -*- */

MODULE = Gfsm		PACKAGE = Gfsm::Automaton         PREFIX = gfsm_automaton

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Linear lookup
void
gfsm_automaton_lookup(gfsmAutomaton *fst, gfsmLabelVector *input, gfsmAutomaton *result, gfsmStateId max_result_states)
CODE:
 if (max_result_states == 0) max_result_states = gfsmLookupMaxResultStates;
 gfsm_automaton_lookup_full(fst,input,result,NULL,max_result_states);
CLEANUP:
 g_ptr_array_free(input,TRUE);

##--------------------------------------------------------------
## linear lookup, saving state-map
gfsmStateIdVector *
gfsm_automaton_lookup_full(gfsmAutomaton *fst, gfsmLabelVector *input, gfsmAutomaton *result, gfsmStateId max_result_states)
PREINIT:
 gfsmStateIdVector *statemap;
CODE:
 statemap = g_ptr_array_sized_new(gfsmLookupStateMapGet);
 statemap->len = 0;
 gfsm_automaton_lookup_full(fst,input,result,statemap,max_result_states);
 RETVAL = statemap;
OUTPUT:
 RETVAL
CLEANUP:
 g_ptr_array_free(statemap,TRUE);
 g_ptr_array_free(input,TRUE);



##--------------------------------------------------------------
## Viterbi lookup
void
gfsm_automaton_lookup_viterbi(gfsmAutomaton *fst, gfsmLabelVector *input, gfsmAutomaton *trellis)
CLEANUP:
 g_ptr_array_free(input,TRUE);
