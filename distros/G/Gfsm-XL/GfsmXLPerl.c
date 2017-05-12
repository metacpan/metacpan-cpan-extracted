#include "GfsmXLPerl.h"
#include <fcntl.h>

#undef VERSION
#include <gfsmxlConfig.h>

/*======================================================================
 * Memory Stuff
 */
//----------------------------------------------------------------------
gpointer gfsm_perl_malloc(gsize n_bytes)
{
  gpointer ptr=NULL;
  Newc(0, ptr, n_bytes, char, gpointer);
  return ptr;
}

//----------------------------------------------------------------------
gpointer gfsm_perl_realloc(gpointer mem, gsize n_bytes)
{
  Renewc(mem, n_bytes, char, gpointer);
  return mem;
}

//----------------------------------------------------------------------
void gfsm_perl_free(gpointer mem)
{
  Safefree(mem);
}

/*======================================================================
 * Gfsm::XL::Cascade Utilities
 */

//----------------------------------------------------------------------
gfsmxlCascadePerl *gfsmxl_perl_cascade_new(void)
{
  gfsmxlCascadePerl *cscp = gfsm_slice_new0(gfsmxlCascadePerl);
  cscp->av = newAV();
  return cscp;
}

//----------------------------------------------------------------------
void gfsmxl_perl_cascade_clear(gfsmxlCascadePerl *cscp)
{
  if (cscp->csc) gfsmxl_cascade_clear(cscp->csc,FALSE);
  if (cscp->av) av_clear(cscp->av);
}

//----------------------------------------------------------------------
void gfsmxl_perl_cascade_free(gfsmxlCascadePerl *cscp)
{
  if (cscp) {
    gfsmxl_perl_cascade_clear(cscp);
    av_undef(cscp->av);
    if (cscp->csc) gfsmxl_cascade_free(cscp->csc,FALSE);
    gfsm_slice_free(gfsmxlCascadePerl,cscp);
  }
}

//----------------------------------------------------------------------
SV *gfsmxl_perl_cascade_get_sv(gfsmxlCascadePerl *cscp, int i)
{
  SV **fetched = av_fetch(cscp->av, i, 0);
  if (fetched) {
    SV *rv = sv_mortalcopy(*fetched);
    SvREFCNT_inc(rv);
    return rv;
  }
  return &PL_sv_undef;
}

//----------------------------------------------------------------------
SV *gfsmxl_perl_cascade_pop_sv(gfsmxlCascadePerl *cscp)
{
  SV *rv = gfsmxl_perl_cascade_get_sv(cscp, cscp->csc->depth-1);
  av_delete(cscp->av, cscp->csc->depth-1, G_DISCARD);
  gfsmxl_cascade_pop(cscp->csc);
  return rv;
}

//----------------------------------------------------------------------
void  gfsmxl_perl_cascade_append_sv(gfsmxlCascadePerl *cscp, SV *xfsm_sv)
{
  gfsmIndexedAutomaton *xfsm = (gfsmIndexedAutomaton*)GINT_TO_POINTER( SvIV((SV*)SvRV(xfsm_sv)) );
  SV *xfsm_sv_copy;
  GFSMXL_DEBUG_EVAL( g_printerr("cascade_append_sv(cscp=%p, cscp->csc=%p): xfsm_sv=%p, xfsm=%p\n", cscp, cscp->csc, xfsm_sv, xfsm); )
  //
  xfsm_sv_copy = sv_mortalcopy(xfsm_sv);     //-- array-stored value (mortal)
  SvREFCNT_inc(xfsm_sv_copy);                //   : mortal needs incremented refcnt
  av_push(cscp->av, xfsm_sv_copy);           //   : store
  //
  gfsmxl_cascade_append_indexed(cscp->csc, xfsm);
}

//----------------------------------------------------------------------
void  gfsmxl_perl_cascade_set_sv(gfsmxlCascadePerl *cscp, guint n, SV *xfsm_sv)
{
  gfsmIndexedAutomaton *xfsm = (gfsmIndexedAutomaton*)GINT_TO_POINTER( SvIV((SV*)SvRV(xfsm_sv)) );
  SV *xfsm_sv_copy;
  I32 key = n;
  GFSMXL_DEBUG_EVAL( g_printerr("cascade_set_sv(cscp=%p, cscp->csc=%p, n=%u): BEGIN: xfsm_sv=%p, xfsm=%p\n", cscp, cscp->csc, n, xfsm_sv, xfsm); )
  av_delete(cscp->av, n, G_DISCARD); //-- delete old value (if any)
  //
  xfsm_sv_copy = sv_mortalcopy(xfsm_sv);     //-- array-stored value (mortal)
  SvREFCNT_inc(xfsm_sv_copy);                //   : mortal needs incremented refcnt
  av_store(cscp->av, key, xfsm_sv_copy);     //   : store at position $n
  //
  gfsmxl_cascade_set_nth_indexed(cscp->csc, n, xfsm, FALSE);	//-- don't free old automaton (perl refcount should take care of that)
}

//----------------------------------------------------------------------
void gfsmxl_perl_cascade_refresh_av(gfsmxlCascadePerl *cscp)
{
  int i;
  av_clear(cscp->av);
  for (i=0; i < cscp->csc->depth; i++) {
    gfsmIndexedAutomaton *xfsm = gfsmxl_cascade_index(cscp->csc,i);
    SV                   *svrv = newSV(0);
    sv_setref_pv(svrv, "Gfsm::Automaton::Indexed", (void*)xfsm);
    av_push(cscp->av, svrv);
  }
}

/*======================================================================
 * Gfsm::XL::Cascade::Lookup Utilities
 */

//----------------------------------------------------------------------
void gfsmxl_perl_cascade_lookup_set_cascade_sv(gfsmxlCascadeLookupPerl *clp, SV *csc_sv)
{
  SvSetSV(clp->csc_sv, csc_sv);
  clp->cl->csc = NULL;  //-- must be explicit, or else madness may ensue
  if (csc_sv && SvROK(csc_sv)) {
    gfsmxlCascadePerl *cscp = (gfsmxlCascadePerl*)GINT_TO_POINTER( SvIV((SV*)SvRV(csc_sv)) );
    //SvREFCNT_inc((SV*)SvRV(csc_sv)); //-- should NOT be necessary if the reference itself was copied using SvSetSV()!
    //GFSMXL_DEBUG_EVAL(g_printerr(": cl_set_cascade_sv[clp=%p, csc_sv=%p, clp->csc_sv=%p]: copy()\n", clp, csc_sv, clp->csc_sv);)
    gfsmxl_cascade_lookup_set_cascade(clp->cl, cscp->csc);
  } else {
    //GFSMXL_DEBUG_EVAL(g_printerr(": cl_set_cascade_sv[clp=%p, csc_sv=%p, clp->csc_sv=%p]: clp->csc_sv=NULL\n", clp, csc_sv, clp->csc_sv);)
    gfsmxl_cascade_lookup_set_cascade(clp->cl, NULL);
  }
  //GFSMXL_DEBUG_EVAL(g_printerr(": cl_set_cascade_sv[clp=%p, csc_sv=%p, clp->csc_sv=%p]: exiting.\n", clp, csc_sv, clp->csc_sv);)
}

//----------------------------------------------------------------------
gfsmxlCascadeLookupPerl *gfsmxl_perl_cascade_lookup_new(SV *csc_sv, gfsmWeight max_w, guint max_paths, guint max_ops)
{
  gfsmxlCascadeLookupPerl *clp = (gfsmxlCascadeLookupPerl*)gfsm_slice_new0(gfsmxlCascadeLookupPerl);
  clp->cl                      = gfsmxl_cascade_lookup_new_full(NULL, max_w, max_paths, max_ops);
  clp->csc_sv                  = newSV(0);
  GFSMXL_DEBUG_EVAL( g_printerr("cascade_lookup_new(clp=%p): created clp->csc_sv=%p (REFCNT=%u)\n", clp, clp->csc_sv, SvREFCNT(clp->csc_sv)); )
  gfsmxl_perl_cascade_lookup_set_cascade_sv(clp, csc_sv);
  GFSMXL_DEBUG_EVAL( g_printerr("cascade_lookup_new(clp=%p): post set_cascade_sv: clp->csc_sv=%p (REFCNT=%u)\n", clp, clp->csc_sv, SvREFCNT(clp->csc_sv)); )
  return clp;
}

//----------------------------------------------------------------------
void gfsmxl_perl_cascade_lookup_free (gfsmxlCascadeLookupPerl *clp)
{
  clp->cl->csc = NULL;
  gfsmxl_cascade_lookup_free(clp->cl);
  SvREFCNT_dec(clp->csc_sv);
  gfsm_slice_free(gfsmxlCascadeLookupPerl,clp);
}

/*======================================================================
 * Type conversions
 */

//----------------------------------------------------------------------
AV *gfsm_perl_ptr_array_to_av_uv(GPtrArray *ary)
{
  AV *av = newAV();
  guint i;
  for (i=0; i < ary->len; i++) {
    av_push(av, newSVuv((UV)GPOINTER_TO_SIZE(g_ptr_array_index(ary,i))));
  }
  sv_2mortal((SV*)av);
  return av;
}


//----------------------------------------------------------------------
HV *gfsm_perl_path_to_hv(gfsmPath *path)
{
  HV *hv = newHV();
  AV *lo = gfsm_perl_ptr_array_to_av_uv(path->lo);
  AV *hi = gfsm_perl_ptr_array_to_av_uv(path->hi);

  hv_store(hv, "lo", 2, newRV((SV*)lo), 0);
  hv_store(hv, "hi", 2, newRV((SV*)hi), 0);
  hv_store(hv, "w",  1, newSVnv(gfsm_perl_weight_getfloat(path->w)), 0);

  sv_2mortal((SV*)hv);
  return hv;
}

//----------------------------------------------------------------------
AV *gfsmxl_perl_patharray_to_av(gfsmxlPathArray *paths_a)
{
  int i;
  AV *RETVAL = newAV();

  for (i=0; i < paths_a->len; i++) {
    gfsmPath *path = (gfsmPath*)g_ptr_array_index(paths_a,i);
    HV       *hv   = gfsm_perl_path_to_hv(path);
    av_push(RETVAL, newRV((SV*)hv));
  }

  sv_2mortal((SV*)RETVAL);  
  return RETVAL;
}



/*======================================================================
 * I/O: Constructors: SV*
 */

//----------------------------------------------------------------------
gfsmIOHandle *gfsmperl_io_new_sv(SV *sv, size_t pos)
{
  gfsmPerlSVHandle *svh = gfsm_slice_new(gfsmPerlSVHandle);
  gfsmIOHandle *ioh = gfsmio_handle_new(gfsmIOTUser,svh);

  SvUTF8_off(sv); //-- unset UTF8 flag for this SV*

  svh->sv = sv;
  svh->pos = pos;

  ioh->read_func = (gfsmIOReadFunc)gfsmperl_read_sv;
  ioh->write_func = (gfsmIOWriteFunc)gfsmperl_write_sv;
  ioh->eof_func = (gfsmIOEofFunc)gfsmperl_eof_sv;

  return ioh;
}

//----------------------------------------------------------------------
void gfsmperl_io_free_sv(gfsmIOHandle *ioh)
{
  gfsmPerlSVHandle *svh = (gfsmPerlSVHandle*)ioh->handle;
  gfsm_slice_free(gfsmPerlSVHandle,svh);
  gfsmio_handle_free(ioh);
}

/*======================================================================
 * I/O: Methods: SV*
 */
//----------------------------------------------------------------------
gboolean gfsmperl_eof_sv(gfsmPerlSVHandle *svh)
{ return svh && svh->sv ? (STRLEN)svh->pos >= sv_len(svh->sv) : TRUE; }

//----------------------------------------------------------------------
gboolean gfsmperl_read_sv(gfsmPerlSVHandle *svh, void *buf, size_t nbytes)
{
  char *svbytes;
  STRLEN len;
  if (!svh || !svh->sv) return FALSE;

  svbytes = sv_2pvbyte(svh->sv, &len);
  if ((STRLEN)(svh->pos+nbytes) <= len) {
    //-- normal case: just copy
    memcpy(buf, svbytes+svh->pos, nbytes);
    svh->pos += nbytes;
    return TRUE;
  }
  //-- overflow: grab what we can
  memcpy(buf, svbytes+svh->pos, len-svh->pos);
  svh->pos = len;
  return FALSE;
}

//----------------------------------------------------------------------
gboolean gfsmperl_write_sv(gfsmPerlSVHandle *svh, const void *buf, size_t nbytes)
{
  if (!svh || !svh->sv) return FALSE;
  sv_catpvn(svh->sv, buf, (STRLEN)nbytes);
  return TRUE;
}
