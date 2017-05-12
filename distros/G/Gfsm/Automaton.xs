#/*-*- Mode: C -*- */

MODULE = Gfsm		PACKAGE = Gfsm::Automaton           PREFIX = gfsm_automaton_

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
gfsmAutomaton*
new(char *CLASS, gboolean is_transducer=1, gfsmSRType srtype=gfsmAutomatonDefaultSRType, guint size=gfsmAutomatonDefaultSize)
PREINIT:
 gfsmAutomatonFlags flags = gfsmAutomatonDefaultFlags;
CODE:
 flags.is_transducer = is_transducer;
 RETVAL = gfsm_automaton_new_full(flags, srtype, size);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Constructor: clone (full copy)
gfsmAutomaton*
clone(gfsmAutomaton *fsm)
PREINIT:
 char *CLASS=HvNAME(SvSTASH(SvRV(ST(0))));  // needed by typemap
CODE:
 RETVAL = gfsm_automaton_clone(fsm);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Constructor: shadow (shallow copy)
gfsmAutomaton*
shadow(gfsmAutomaton *fsm)
PREINIT:
 char *CLASS=HvNAME(SvSTASH(SvRV(ST(0))));  // needed by typemap
CODE:
 RETVAL = gfsm_automaton_shadow(fsm);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Assignment
void
fsm_automaton_assign(gfsmAutomaton *dst, gfsmAutomaton *src)
CODE:
 gfsm_automaton_copy(dst,src);


##--------------------------------------------------------------
## clear
void
gfsm_automaton_clear(gfsmAutomaton *fsm)

##--------------------------------------------------------------
## Destructor: DESTROY()
void
DESTROY(gfsmAutomaton* fsm)
CODE:
 GFSM_PERL_DEBUG_EVAL( g_printerr("Gfsm::Automaton::DESTROY(fsm=%p)\n", fsm); )
 if (fsm) gfsm_automaton_free(fsm);
 gfsm_perl_blow_chunks();


##=====================================================================
## Accessors: Properties
##=====================================================================

##--------------------------------------------------------------
## accessors: properties: flags

gboolean
is_transducer(gfsmAutomaton *fsm, ...)
CODE:
 if (items > 1) {
   fsm->flags.is_transducer = SvIV(ST(1));
 }
 RETVAL = fsm->flags.is_transducer;
OUTPUT:
 RETVAL

gboolean
is_weighted(gfsmAutomaton *fsm, ...)
CODE:
 if (items > 1) {
   fsm->flags.is_weighted = SvIV(ST(1));
 }
 RETVAL = fsm->flags.is_weighted;
OUTPUT:
 RETVAL

gfsmArcSortMode
sort_mode(gfsmAutomaton *fsm, ...)
CODE:
 if (items > 1) {
   fsm->flags.sort_mode = SvIV(ST(1));
 }
 RETVAL = fsm->flags.sort_mode;
OUTPUT:
 RETVAL

gboolean
is_deterministic(gfsmAutomaton *fsm, ...)
CODE:
 if (items > 1) {
   fsm->flags.is_deterministic = SvIV(ST(1));
 }
 RETVAL = fsm->flags.is_deterministic;
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## accessors: properties

gfsmSRType
semiring_type(gfsmAutomaton *fsm, ...)
CODE:
 if (items > 1) {
   gfsm_automaton_set_semiring_type(fsm, (gfsmSRType)SvIV(ST(1)));
 }
 RETVAL = (fsm->sr ? fsm->sr->type : gfsmSRTUnknown);
OUTPUT:
 RETVAL

guint
gfsm_automaton_n_states(gfsmAutomaton *fsm)

guint
gfsm_automaton_n_final_states(gfsmAutomaton *fsm)

guint
gfsm_automaton_n_arcs(gfsmAutomaton *fsm)

gfsmStateId
root(gfsmAutomaton *fsm, ...)
CODE:
 if (items > 1) {
   gfsm_automaton_set_root(fsm, (gfsmStateId)SvIV(ST(1)));
 }
 RETVAL = gfsm_automaton_get_root(fsm);
OUTPUT:
 RETVAL

gboolean
gfsm_automaton_has_state(gfsmAutomaton *fsm, gfsmStateId id)

gboolean
gfsm_automaton_is_cyclic(gfsmAutomaton *fsm)

gboolean
gfsm_automaton_is_acyclic(gfsmAutomaton *fsm)


##=====================================================================
## Accessors: Automaton: states
##=====================================================================

#//-- add a new state if it doesn't already exist
gfsmStateId
add_state(gfsmAutomaton *fsm, gfsmStateId id=gfsmNoState)
CODE:
 RETVAL = gfsm_automaton_add_state_full(fsm,id);
OUTPUT:
 RETVAL

#//-- ensure that a state exists
gfsmStateId
gfsm_automaton_ensure_state(gfsmAutomaton *fsm, gfsmStateId id)

#//-- remove a state
void
gfsm_automaton_remove_state(gfsmAutomaton *fsm, gfsmStateId id)

#//-- get/set final-state flag
gboolean
is_final(gfsmAutomaton *fsm, gfsmStateId id, ...)
CODE:
 if (items > 2) {
   gfsm_automaton_set_final_state(fsm, id, (gboolean)SvIV(ST(2)));
 }
 RETVAL = gfsm_automaton_is_final_state(fsm, id);
OUTPUT:
 RETVAL

#//-- get/set final-weight
gfsmWeight
final_weight(gfsmAutomaton *fsm, gfsmStateId id, ...)
CODE:
 if (items > 2) {
   gfsmWeight w;
   gfsm_perl_weight_setfloat(w, (gfsmWeightVal)SvNV(ST(2)));
   gfsm_automaton_set_final_state_full(fsm, id, TRUE, w);
 }
 RETVAL = gfsm_automaton_get_final_weight(fsm, id);
OUTPUT:
 RETVAL

#/** Get output-degree of a state */
guint
gfsm_automaton_out_degree(gfsmAutomaton *fsm, gfsmStateId id)

#/** Renumber states of an FSM */
void
gfsm_automaton_renumber_states(gfsmAutomaton *fsm)


##=====================================================================
## Accessors: Automaton: arcs
##=====================================================================

#/** Add an arc from state @q1 to state @q2 with label (@lo,@hi) and weight @w
# *  Missing states are implicitly created.
# */
void gfsm_automaton_add_arc(gfsmAutomaton *fsm, \
			    gfsmStateId q1, \
			    gfsmStateId q2, \
			    gfsmLabelId lo, \
			    gfsmLabelId hi, \
			    gfsmWeight  w)

#/** Sort all arcs in the automaton */
void
gfsm_automaton_arcsort(gfsmAutomaton *fsm, gfsmArcSortMode mode)


##=====================================================================
## I/O
##=====================================================================

##--------------------------------------------------------------
## I/O: binary: FILE*

#/** Load an automaton from a stored binary file (implicitly clear()s @fsm) */
gboolean
_load(gfsmAutomaton *fsm, FILE *f)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh    = gfsmio_new_zfile(f,"rb",-1);
 RETVAL = gfsm_automaton_load_bin_handle(fsm, ioh, &err);
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
_save(gfsmAutomaton *fsm, FILE *f, int zlevel=-1)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh = zlevel ? gfsmio_new_zfile(f,"wb",zlevel) : gfsmio_new_file(f);
 RETVAL = gfsm_automaton_save_bin_handle(fsm, ioh, &err);
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
_load_string(gfsmAutomaton *fsm, SV *str)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh    = gfsmperl_io_new_sv(str,0);
 RETVAL = gfsm_automaton_load_bin_handle(fsm, ioh, &err);
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
_save_string(gfsmAutomaton *fsm, SV *str)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh = gfsmperl_io_new_sv(str,0);
 RETVAL=gfsm_automaton_save_bin_handle(fsm, ioh, &err);
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



##--------------------------------------------------------------
## I/O: text

gboolean
_compile(gfsmAutomaton *fsm, \
	 FILE *f, \
	 gfsmAlphabet *abet_lo=NULL, \
	 gfsmAlphabet *abet_hi=NULL, \
	 gfsmAlphabet *abet_Q=NULL)
PREINIT:
 gfsmError *err=NULL;
CODE:
 RETVAL = gfsm_automaton_compile_file_full(fsm, f, abet_lo, abet_hi, abet_Q, &err);
 if (err && err->message) {
   SV *perlerr = get_sv("Gfsm::Error",TRUE);
   sv_setpv(perlerr, err->message);
   g_error_free(err);
 }
OUTPUT:
 RETVAL

gboolean
_compile_string(gfsmAutomaton *fsm, \
 	       SV            *str, \
	       gfsmAlphabet  *abet_lo=NULL, \
	       gfsmAlphabet  *abet_hi=NULL, \
	       gfsmAlphabet  *abet_Q=NULL)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh    = gfsmperl_io_new_sv(str,0);
 RETVAL = gfsm_automaton_compile_handle(fsm, ioh, abet_lo, abet_hi, abet_Q, &err);
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


gboolean
_print_att(gfsmAutomaton *fsm, \
	   FILE *f, \
	   gfsmAlphabet *abet_lo=NULL, \
	   gfsmAlphabet *abet_hi=NULL, \
	   gfsmAlphabet *abet_Q=NULL, \
	   int           zlevel=0)
PREINIT:
 gfsmError *err=NULL;
CODE:
 RETVAL=gfsm_automaton_print_file_full(fsm, f, abet_lo, abet_hi, abet_Q, zlevel, &err);
 if (err && err->message) {
   SV *perlerr = get_sv("Gfsm::Error",TRUE);
   sv_setpv(perlerr, err->message);
   g_error_free(err);
 }
OUTPUT:
 RETVAL

gboolean
_print_att_string(gfsmAutomaton *fsm, \
		 SV            *str, \
		 gfsmAlphabet  *abet_lo=NULL, \
		 gfsmAlphabet  *abet_hi=NULL, \
		 gfsmAlphabet  *abet_Q=NULL)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh    = gfsmperl_io_new_sv(str,0);
 RETVAL = gfsm_automaton_print_handle(fsm, ioh, abet_lo, abet_hi, abet_Q, &err);
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


##--------------------------------------------------------------
## I/O: draw: vcg
gboolean
_draw_vcg(gfsmAutomaton *fsm, \
	 FILE          *f, \
	 gfsmAlphabet  *lo_alphabet=NULL, \
	 gfsmAlphabet  *hi_alphabet=NULL, \
	 gfsmAlphabet  *state_alphabet=NULL, \
	 const char   *title="gfsm", \
	 int           xspace=40, \
	 int           yspace=20, \
	 const char   *orientation="left_to_right", \
	 const char   *state_shape="box", \
	 const char   *state_color="white", \
	 const char   *final_color="lightgrey")
PREINIT:
 gfsmError *err=NULL;
CODE:
 RETVAL=gfsm_automaton_draw_vcg_file_full(fsm, f, lo_alphabet, hi_alphabet, state_alphabet, title, xspace, yspace, orientation, state_shape, state_color, final_color, &err);
 if (err && err->message) {
   SV *perlerr = get_sv("Gfsm::Error",TRUE);
   sv_setpv(perlerr, err->message);
   g_error_free(err);
 }
OUTPUT:
 RETVAL

gboolean
_draw_dot(gfsmAutomaton *fsm, \
	 FILE          *f, \
	 gfsmAlphabet  *lo_alphabet=NULL, \
	 gfsmAlphabet  *hi_alphabet=NULL, \
	 gfsmAlphabet  *state_alphabet=NULL, \
	 const char   *title="gfsm", \
	 float          width=8.5, \
	 float          height=11, \
	 int            fontsize=14, \
	 const char   *fontname=NULL, \
	 gboolean       portrait=FALSE, \
	 gboolean       vertical=FALSE, \
	 float          nodesep=0.25, \
	 float          ranksep=0.40)
PREINIT:
 gfsmError *err=NULL;
CODE:
 RETVAL=gfsm_automaton_draw_dot_file_full(fsm, f, lo_alphabet, hi_alphabet, state_alphabet, title, width, height, fontsize, fontname, portrait, vertical, nodesep, ranksep, &err);
 if (err && err->message) {
   SV *perlerr = get_sv("Gfsm::Error",TRUE);
   sv_setpv(perlerr, err->message);
   g_error_free(err);
 }
OUTPUT:
 RETVAL
