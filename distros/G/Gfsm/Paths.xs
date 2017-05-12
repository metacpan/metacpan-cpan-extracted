#/*-*- Mode: C -*- */

MODULE = Gfsm		PACKAGE = Gfsm::Automaton           PREFIX = gfsm_automaton_

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## automaton paths (hash-refs)

AV *
paths(gfsmAutomaton *fsm, gfsmLabelSide which=-1)
PREINIT:
 gfsmSet   *paths_s=NULL;
CODE:
 if (which < 0) {
   which = fsm->flags.is_transducer ? gfsmLSBoth : gfsmLSLower;
 }
 paths_s = gfsm_automaton_paths_full(fsm,NULL,which);
 RETVAL  = gfsm_perl_paths_to_av(paths_s);
 //
 gfsm_set_free(paths_s);
 //
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## automaton arc-paths (hash-refs, aligned)
AV *
arcpaths(gfsmAutomaton *fsm)
PREINIT:
 GSList *arcpaths=NULL;
CODE:
 arcpaths = gfsm_automaton_arcpaths(fsm);
 RETVAL   = gfsm_perl_arcpaths_to_av(arcpaths);
 gfsm_arcpath_list_free(arcpaths);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Viterbi Trellis paths
AV *
viterbi_trellis_paths(gfsmAutomaton *trellis, gfsmLabelSide which=gfsmLSUpper)
PREINIT:
 gfsmSet   *paths_s=NULL;
CODE:
 paths_s = gfsm_viterbi_trellis_paths_full(trellis,NULL,which);
 RETVAL  = gfsm_perl_paths_to_av(paths_s);
 //
 gfsm_set_free(paths_s);
 //
OUTPUT:
 RETVAL


##--------------------------------------------------------------
## Viterbi Trellis best-path
HV *
viterbi_trellis_bestpath(gfsmAutomaton *trellis, gfsmLabelSide which=gfsmLSUpper)
PREINIT:
 gfsmPath *path=NULL;
CODE:
 path   = gfsm_viterbi_trellis_bestpath_full(trellis,NULL,which);
 RETVAL = gfsm_perl_path_to_hv(path);
 //
 gfsm_path_free(path);
 //
OUTPUT:
 RETVAL
