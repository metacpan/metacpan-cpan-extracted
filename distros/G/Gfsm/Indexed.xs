#/*-*- Mode: C -*- */

MODULE = Gfsm		PACKAGE = Gfsm::Automaton::Indexed    PREFIX = gfsm_indexed_automaton_

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
gfsmIndexedAutomaton*
new(char *CLASS, gboolean is_transducer=1, gfsmSRType srtype=gfsmAutomatonDefaultSRType, guint n_states=gfsmAutomatonDefaultSize, guint n_arcs=gfsmAutomatonDefaultSize)
PREINIT:
 gfsmAutomatonFlags flags = gfsmAutomatonDefaultFlags;
CODE:
 flags.is_transducer = is_transducer;
 RETVAL = gfsm_indexed_automaton_new_full(flags, srtype, n_states, n_arcs);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Constructor: clone (full copy)
gfsmIndexedAutomaton*
clone(gfsmIndexedAutomaton *xfsm)
PREINIT:
 char *CLASS=HvNAME(SvSTASH(SvRV(ST(0))));  // needed by typemap
CODE:
 RETVAL = gfsm_indexed_automaton_clone(xfsm);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Assignment
void
gfsm_indexed_automaton_assign(gfsmIndexedAutomaton *dst, gfsmIndexedAutomaton *src)
CODE:
 gfsm_indexed_automaton_copy(dst,src);


##--------------------------------------------------------------
## clear
void
gfsm_indexed_automaton_clear(gfsmIndexedAutomaton *xfsm)

##--------------------------------------------------------------
## Destructor: DESTROY()
void
DESTROY(gfsmIndexedAutomaton* xfsm)
CODE:
 GFSM_PERL_DEBUG_EVAL( g_printerr("Gfsm::Automaton::Indexed::DESTROY(sclr=%p, xfsm=%p)\n", ST(0), xfsm); )
 if (xfsm) gfsm_indexed_automaton_free(xfsm);
 gfsm_perl_blow_chunks();


##=====================================================================
## Import & Export
##=====================================================================

MODULE = Gfsm	   PACKAGE = Gfsm::Automaton             PREFIX = gfsm_automaton_

gfsmIndexedAutomaton *
to_indexed(gfsmAutomaton *fsm)
PREINIT:
//char *CLASS=HvNAME(SvSTASH(SvRV(ST(0))));  // needed by typemap
  char *CLASS="Gfsm::Automaton::Indexed";  // needed by typemap
CODE:
 RETVAL = gfsm_automaton_to_indexed(fsm, NULL);
OUTPUT:
 RETVAL


MODULE = Gfsm	   PACKAGE = Gfsm::Automaton::Indexed    PREFIX = gfsm_indexed_automaton_

gfsmAutomaton *
to_automaton(gfsmIndexedAutomaton *xfsm)
PREINIT:
//char *CLASS=HvNAME(SvSTASH(SvRV(ST(0))));  // needed by typemap
  char *CLASS="Gfsm::Automaton";  // needed by typemap
CODE:
 RETVAL = gfsm_indexed_to_automaton(xfsm, NULL);
OUTPUT:
 RETVAL


##=====================================================================
## Accessors: Properties
##=====================================================================

##--------------------------------------------------------------
## accessors: properties: flags

gboolean
is_transducer(gfsmIndexedAutomaton *xfsm, ...)
CODE:
 if (items > 1) {
   xfsm->flags.is_transducer = SvIV(ST(1));
 }
 RETVAL = xfsm->flags.is_transducer;
OUTPUT:
 RETVAL

gboolean
is_weighted(gfsmIndexedAutomaton *xfsm, ...)
CODE:
 if (items > 1) {
   xfsm->flags.is_weighted = SvIV(ST(1));
 }
 RETVAL = xfsm->flags.is_weighted;
OUTPUT:
 RETVAL

gfsmArcSortMode
sort_mode(gfsmIndexedAutomaton *xfsm, ...)
CODE:
 if (items > 1) {
   xfsm->flags.sort_mode = SvIV(ST(1));
 }
 RETVAL = xfsm->flags.sort_mode;
OUTPUT:
 RETVAL

gboolean
is_deterministic(gfsmIndexedAutomaton *xfsm, ...)
CODE:
 if (items > 1) {
   xfsm->flags.is_deterministic = SvIV(ST(1));
 }
 RETVAL = xfsm->flags.is_deterministic;
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## accessors: properties

gfsmSRType
semiring_type(gfsmIndexedAutomaton *xfsm, ...)
CODE:
 if (items > 1) {
   gfsm_indexed_automaton_set_semiring_type(xfsm, (gfsmSRType)SvIV(ST(1)));
 }
 RETVAL = (xfsm->sr ? xfsm->sr->type : gfsmSRTUnknown);
OUTPUT:
 RETVAL

guint
gfsm_indexed_automaton_n_states(gfsmIndexedAutomaton *xfsm)

guint
gfsm_indexed_automaton_n_arcs(gfsmIndexedAutomaton *xfsm)

gfsmStateId
root(gfsmIndexedAutomaton *xfsm, ...)
CODE:
 if (items > 1) {
   gfsm_indexed_automaton_set_root(xfsm, (gfsmStateId)SvIV(ST(1)));
 }
 RETVAL = gfsm_indexed_automaton_get_root(xfsm);
OUTPUT:
 RETVAL

gboolean
gfsm_indexed_automaton_has_state(gfsmIndexedAutomaton *xfsm, gfsmStateId id)


##=====================================================================
## Accessors: Automaton: states
##=====================================================================

#//-- ensure that a state exists
gfsmStateId
gfsm_indexed_automaton_ensure_state(gfsmIndexedAutomaton *xfsm, gfsmStateId id)

#//-- remove a state (currently does nothing)
void
gfsm_indexed_automaton_remove_state(gfsmIndexedAutomaton *xfsm, gfsmStateId id)

#//-- get/set final-state flag
gboolean
is_final(gfsmIndexedAutomaton *xfsm, gfsmStateId id, ...)
CODE:
 if (items > 2) {
   gfsm_indexed_automaton_set_final_state(xfsm, id, (gboolean)SvIV(ST(2)));
 }
 RETVAL = gfsm_indexed_automaton_state_is_final(xfsm, id);
OUTPUT:
 RETVAL

#//-- get/set final-weight
gfsmWeight
final_weight(gfsmIndexedAutomaton *xfsm, gfsmStateId id, ...)
CODE:
 if (items > 2) {
   gfsmWeight w;
   gfsm_perl_weight_setfloat(w, (gfsmWeightVal)SvNV(ST(2)));
   gfsm_indexed_automaton_set_final_state_full(xfsm, id, TRUE, w);
 }
 RETVAL = gfsm_indexed_automaton_get_final_weight(xfsm, id);
OUTPUT:
 RETVAL

#/** Get output-degree of a state */
guint
gfsm_indexed_automaton_out_degree(gfsmIndexedAutomaton *xfsm, gfsmStateId id)

#/** Renumber states of an FSM */
#/*void gfsm_automaton_renumber_states(gfsmIndexedAutomaton *xfsm)*/


##=====================================================================
## Accessors: Automaton: arcs
##=====================================================================

#/** Sort all arcs in the automaton */
void
gfsm_indexed_automaton_arcsort(gfsmIndexedAutomaton *xfsm, gfsmArcCompMask sort_mask);
CODE:
 gfsm_indexed_automaton_sort(xfsm,sort_mask);



##=====================================================================
## I/O
##=====================================================================

##--------------------------------------------------------------
## I/O: binary: FILE*

#/** Load an automaton from a stored binary file (implicitly clear()s @fsm) */
gboolean
_load(gfsmIndexedAutomaton *xfsm, FILE *f)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh    = gfsmio_new_zfile(f,"rb",-1);
 RETVAL = gfsm_indexed_automaton_load_bin_handle(xfsm, ioh, &err);
 if (err && err->message) {
   SV *perlerr = get_sv("Gfsm::Error",TRUE);
   sv_setpv(perlerr, err->message);
   g_error_free(err);
 }
 if (ioh) {
   /*gfsmio_close(ioh);*/
   gfsmio_handle_free(ioh);
 }
OUTPUT:
  RETVAL


#/** Save an automaton to a binary FILE* */
gboolean
_save(gfsmIndexedAutomaton *xfsm, FILE *f, int zlevel=-1)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh = zlevel ? gfsmio_new_zfile(f,"wb",zlevel) : gfsmio_new_file(f);
 RETVAL = gfsm_indexed_automaton_save_bin_handle(xfsm, ioh, &err);
 if (err && err->message) {
   SV *perlerr = get_sv("Gfsm::Error",TRUE);
   sv_setpv(perlerr, err->message);
   g_error_free(err);
 }
 if (ioh) {
   if (ioh->iotype==gfsmIOTZFile) gfsmio_close(ioh);
   gfsmio_handle_free(ioh);
 }
OUTPUT:
  RETVAL

##--------------------------------------------------------------
## I/O: binary: SV*

#/** Load an automaton from a scalar buffer (implicitly clear()s @fsm) */
gboolean
load_string(gfsmIndexedAutomaton *xfsm, SV *str)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh    = gfsmperl_io_new_sv(str,0);
 RETVAL = gfsm_indexed_automaton_load_bin_handle(xfsm, ioh, &err);
 if (err && err->message) {
   SV *perlerr = get_sv("Gfsm::Error",TRUE);
   sv_setpv(perlerr, err->message);
   g_error_free(err);
 }
 if (ioh) {
   gfsmperl_io_free_sv(ioh);
 }
OUTPUT:
  RETVAL

#/** Save an automaton to a scalar */
gboolean
save_string(gfsmIndexedAutomaton *xfsm, SV *str)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh = gfsmperl_io_new_sv(str,0);
 RETVAL=gfsm_indexed_automaton_save_bin_handle(xfsm, ioh, &err);
 if (err && err->message) {
   SV *perlerr = get_sv("Gfsm::Error",TRUE);
   sv_setpv(perlerr, err->message);
   g_error_free(err);
 }
 if (ioh) {
   gfsmperl_io_free_sv(ioh);
 }
OUTPUT:
  RETVAL
