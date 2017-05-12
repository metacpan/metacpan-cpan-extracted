#/*-*- Mode: C -*- */

MODULE = Gfsm		PACKAGE = Gfsm::Automaton           PREFIX = gfsm_

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

void statesort_aff(gfsmAutomaton *fsm)
CODE:
  gfsm_statesort_aff(fsm,NULL);

void statesort_dfs(gfsmAutomaton *fsm)
CODE:
  gfsm_statesort_dfs(fsm,NULL);

void statesort_bfs(gfsmAutomaton *fsm)
CODE:
  gfsm_statesort_bfs(fsm,NULL);


gfsmStateIdMap* depths(gfsmAutomaton *fsm)
PREINIT:
 gfsmStateIdMap *depths=NULL;
CODE:
 depths = gfsm_statemap_depths(fsm,NULL);
 RETVAL = depths;
OUTPUT:
 RETVAL
CLEANUP:
 g_array_free(depths,TRUE);
