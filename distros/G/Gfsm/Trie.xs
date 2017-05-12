#/*-*- Mode: C -*- */

MODULE = Gfsm		PACKAGE = Gfsm::Automaton           PREFIX = gfsm_trie_

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
gfsmTrie*
newTrie(char *CLASS, gboolean is_transducer=1, gfsmSRType srtype=gfsmTrieDefaultSRType, guint size=gfsmAutomatonDefaultSize)
PREINIT:
 gfsmAutomatonFlags flags = gfsmTrieDefaultFlags;
CODE:
 flags.is_transducer = is_transducer;
 RETVAL = gfsm_automaton_new_full(flags, srtype, size);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Methods: add path

##gfsm_trie_add_path(gfsmTrie *trie, gfsmLabelVector *lo, gfsmLabelVector *hi, gfsmWeight w={0}, gboolean add_to_arcs=TRUE, gboolean add_to_state_final=FALSE, gboolean add_to_path_final=TRUE)

gfsmStateId
gfsm_trie_add_path(gfsmTrie *trie, gfsmLabelVector *lo, gfsmLabelVector *hi, ...)
PREINIT:
 gfsmWeight w;
 gboolean add_to_arcs = TRUE;
 gboolean add_to_state_final = FALSE;
 gboolean add_to_path_final = TRUE;
CODE:
 if (items >= 4) { gfsm_perl_weight_setfloat(w, (gfsmWeightVal)SvNV(ST(3))); }
 else            { gfsm_perl_weight_setfloat(w, 0); }
 if (items >= 5) { add_to_arcs = SvIV(ST(4)); }
 if (items >= 6) { add_to_state_final = SvIV(ST(5)); }
 if (items >= 6) { add_to_path_final = SvIV(ST(6)); }
 RETVAL = gfsm_trie_add_path_full(trie, lo, hi, w, add_to_arcs, add_to_state_final, add_to_path_final, NULL);
OUTPUT:
 RETVAL
CLEANUP:
 if (lo) g_ptr_array_free(lo,TRUE);
 if (hi) g_ptr_array_free(hi,TRUE);

##--------------------------------------------------------------
## Methods: add path (+states)

#gfsm_trie_add_path_states(gfsmTrie *trie, gfsmLabelVector *lo, gfsmLabelVector *hi, gfsmWeight w={0}, gboolean add_to_arcs=TRUE, gboolean add_to_state_final=FALSE, gboolean add_to_path_final=TRUE

gfsmStateIdVector*
gfsm_trie_add_path_states(gfsmTrie *trie, gfsmLabelVector *lo, gfsmLabelVector *hi, ...)
PREINIT:
 gfsmWeight w;
 gboolean add_to_arcs = TRUE;
 gboolean add_to_state_final = FALSE;
 gboolean add_to_path_final = TRUE;
CODE:
 if (items >= 4) { gfsm_perl_weight_setfloat(w, (gfsmWeightVal)SvNV(ST(3))); }
 else            { gfsm_perl_weight_setfloat(w, 0); }
 if (items >= 5) { add_to_arcs = SvIV(ST(4)); }
 if (items >= 6) { add_to_state_final = SvIV(ST(5)); }
 if (items >= 6) { add_to_path_final = SvIV(ST(6)); }
 RETVAL = g_ptr_array_sized_new(lo->len + hi->len);
 gfsm_trie_add_path_full(trie, lo, hi, w, add_to_arcs, add_to_state_final, add_to_path_final, RETVAL);
OUTPUT:
 RETVAL
CLEANUP:
 if (lo) g_ptr_array_free(lo,TRUE);
 if (hi) g_ptr_array_free(hi,TRUE);
 if (RETVAL) g_ptr_array_free(RETVAL,TRUE);


##--------------------------------------------------------------
## Methods: find prefix
void
gfsm_trie_find_prefix(gfsmTrie *trie, gfsmLabelVector *lo, gfsmLabelVector *hi)
PREINIT:
 gfsmStateId qid;
 guint lo_i;
 guint hi_i;
 gfsmWeight w_last;
 guint nitems = 1;
PPCODE:
{
  qid = gfsm_trie_find_prefix(trie, lo,hi, &lo_i,&hi_i,&w_last, NULL);
  //
  //
  //-- return stack
  ST(0) = newSVuv(qid);
  sv_2mortal(ST(0));
  if (GIMME_V == G_ARRAY) {
    nitems = 4;
    ST(1) = newSVuv(lo_i);
    ST(2) = newSVuv(hi_i);
    ST(3) = newSVnv(gfsm_perl_weight_getfloat(w_last));
    sv_2mortal(ST(1));
    sv_2mortal(ST(2));
    sv_2mortal(ST(3));
  }
  //
  //-- cleanup
  if (lo) g_ptr_array_free(lo,TRUE);
  if (hi) g_ptr_array_free(hi,TRUE);
  //
  //-- return
  XSRETURN(nitems);
}

##--------------------------------------------------------------
## Methods: find prefix (+states)
void
gfsm_trie_find_prefix_states(gfsmTrie *trie, gfsmLabelVector *lo, gfsmLabelVector *hi)
PREINIT:
 gfsmStateIdVector *qpath;
 AV *qpath_av;
 guint lo_i;
 guint hi_i;
 gfsmWeight w_last;
 guint nitems = 1;
PPCODE:
{
  qpath = g_ptr_array_sized_new(lo->len + hi->len);
  gfsm_trie_find_prefix(trie, lo,hi, &lo_i,&hi_i,&w_last, qpath);
  //
  //
  //-- return stack
  qpath_av = gfsm_perl_ptr_array_to_av_uv(qpath);
  ST(0) = newRV((SV*)qpath_av);
  sv_2mortal(ST(0));
  if (GIMME_V == G_ARRAY) {
    nitems = 4;
    ST(1) = newSVuv(lo_i);
    ST(2) = newSVuv(hi_i);
    ST(3) = newSVnv(gfsm_perl_weight_getfloat(w_last));
    sv_2mortal(ST(1));
    sv_2mortal(ST(2));
    sv_2mortal(ST(3));
  }
  //
  //-- cleanup
  if (lo) g_ptr_array_free(lo,TRUE);
  if (hi) g_ptr_array_free(hi,TRUE);
  if (qpath) g_ptr_array_free(qpath,TRUE);
  //
  //-- return
  XSRETURN(nitems);
}


##--------------------------------------------------------------
## Methods: find arcs
gfsmStateId
gfsm_trie_find_arc_lower(gfsmTrie *trie, gfsmStateId qid, gfsmLabelVal lab)
PREINIT:
 gfsmArc *a;
CODE:
 a=gfsm_trie_find_arc_lower(trie,qid,lab);
 if (a) RETVAL=a->target;
 else   RETVAL=gfsmNoState;
OUTPUT:
 RETVAL

gfsmStateId
gfsm_trie_find_arc_upper(gfsmTrie *trie, gfsmStateId qid, gfsmLabelVal lab)
PREINIT:
 gfsmArc *a;
CODE:
 a=gfsm_trie_find_arc_upper(trie,qid,lab);
 if (a) RETVAL=a->target;
 else   RETVAL=gfsmNoState;
OUTPUT:
 RETVAL


##--------------------------------------------------------------
## Methods: find or insert arcs
gfsmStateId
gfsm_trie_get_arc_lower(gfsmTrie *trie, gfsmStateId qid, gfsmLabelVal lab, gfsmWeight w, gboolean add_weight=TRUE)

gfsmStateId
gfsm_trie_get_arc_upper(gfsmTrie *trie, gfsmStateId qid, gfsmLabelVal lab, gfsmWeight w, gboolean add_weight=TRUE)
