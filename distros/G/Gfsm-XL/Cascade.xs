#/*-*- Mode: C -*- */

MODULE = Gfsm::XL	PACKAGE = Gfsm::XL::Cascade         PREFIX = gfsmxl_cascade_

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
gfsmxlCascadePerl*
new(char *CLASS, guint depth=0, gfsmSRType srtype=gfsmAutomatonDefaultSRType)
CODE:
 RETVAL      = gfsmxl_perl_cascade_new();
 RETVAL->csc = gfsmxl_cascade_new_full(depth, srtype);
 GFSMXL_DEBUG_EVAL(g_printerr("Gfsm::XL::Cascade::new(): returning cascade=%p, csc=%p\n", RETVAL, RETVAL->csc);)
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## clear
void
gfsmxl_cascade_clear(gfsmxlCascadePerl *cscp)
CODE:
 if (cscp) gfsmxl_perl_cascade_clear(cscp);

##--------------------------------------------------------------
## Destructor: DESTROY()
void
DESTROY(gfsmxlCascadePerl* cscp)
CODE:
 GFSMXL_DEBUG_EVAL(g_printerr("Gfsm::XL::Cascade::DESTROY(cscp=%p : cscp->csc=%p, cscp->csc->depth=%u)\n", cscp, (cscp ? cscp->csc : NULL), (cscp && cscp->csc ? cscp->csc->depth : 0));)
 if (cscp) gfsmxl_perl_cascade_free(cscp);
 GFSMXL_BLOW_CHUNKS();

##=====================================================================
## High-level Access
##=====================================================================

guint
gfsmxl_cascade_depth(gfsmxlCascadePerl *cscp)
CODE:
 RETVAL = cscp->csc->depth;
OUTPUT:
 RETVAL

gfsmSRType
gfsmxl_cascade_semiring_type(gfsmxlCascadePerl *cscp, ...)
CODE:
 if (items > 1) {
   gfsmxl_cascade_set_semiring_type(cscp->csc, (gfsmSRType)SvIV(ST(1)));
 }
 RETVAL = (cscp->csc->sr ? cscp->csc->sr->type : gfsmSRTUnknown);
OUTPUT:
 RETVAL

void
gfsmxl_cascade_sort_all(gfsmxlCascadePerl *cscp, gfsmArcCompMask sort_mask)
CODE:
 gfsmxl_cascade_sort_all(cscp->csc, sort_mask);

##=====================================================================
## Component Access
##=====================================================================

void
_append(gfsmxlCascadePerl *cscp, ...)
INIT:
  int i;
CODE:
  for (i=1; i < items; i++) {
    //-- type-checking from "perlobject.map" -> INPUT -> O_OBJECT
    SV *xfsm_sv_i = ST(i);
    if( !sv_isobject(xfsm_sv_i) && (SvTYPE(SvRV(xfsm_sv_i)) == SVt_PVMG) ) {
      warn( "Gfsm::XL::Cascade::append() -- item %d is not a blessed SV reference", i );
      XSRETURN_UNDEF;
    }
    gfsmxl_perl_cascade_append_sv(cscp,xfsm_sv_i);
  }

SV*
gfsmxl_cascade_get(gfsmxlCascadePerl *cscp, int i)
CODE:
 RETVAL = gfsmxl_perl_cascade_get_sv(cscp,i);
OUTPUT:
 RETVAL

SV*
gfsmxl_cascade_pop(gfsmxlCascadePerl *cscp)
CODE:
  if (cscp->csc->depth<=0) { XSRETURN_UNDEF; }
  RETVAL = gfsmxl_perl_cascade_pop_sv(cscp);
OUTPUT:
  RETVAL

SV*
_set(gfsmxlCascadePerl *cscp, guint n, SV *xfsm_sv)
CODE:
  if( !sv_isobject(xfsm_sv) && (SvTYPE(SvRV(xfsm_sv)) == SVt_PVMG) ) {
    warn( "Gfsm::XL::Cascade::set() -- xfsm_sv is not a blessed SV reference" );
    XSRETURN_UNDEF;
  }
  RETVAL = gfsmxl_perl_cascade_get_sv(cscp,n);
  //if (RETVAL) { SvREFCNT_dec(RETVAL); }
  gfsmxl_perl_cascade_set_sv(cscp,n,xfsm_sv);
OUTPUT:
  RETVAL


##=====================================================================
## I/O
##=====================================================================

##--------------------------------------------------------------
## I/O: binary: FILE*

#/** Load a cascade from a stored binary file (implicitly clear()s cascade) */
gboolean
_load(gfsmxlCascadePerl *cscp, FILE *f)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh    = gfsmio_new_zfile(f,"rb",-1);
 gfsmxl_perl_cascade_clear(cscp);
 RETVAL = gfsmxl_cascade_load_bin_handle(cscp->csc, ioh, &err);
 gfsmxl_perl_cascade_refresh_av(cscp);
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

#/** Save a cascade to a binary FILE* */
gboolean
_save(gfsmxlCascadePerl *cscp, FILE *f, int zlevel=-1)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh = zlevel ? gfsmio_new_zfile(f,"wb",zlevel) : gfsmio_new_file(f);
 RETVAL = gfsmxl_cascade_save_bin_handle(cscp->csc, ioh, &err);
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

#/** Load a cascade from a scalar buffer (implicitly clear()s cascade) */
gboolean
load_string(gfsmxlCascadePerl *cscp, SV *str)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh    = gfsmperl_io_new_sv(str,0);
 gfsmxl_perl_cascade_clear(cscp);
 RETVAL = gfsmxl_cascade_load_bin_handle(cscp->csc, ioh, &err);
 gfsmxl_perl_cascade_refresh_av(cscp);
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
save_string(gfsmxlCascadePerl *cscp, SV *str)
PREINIT:
 gfsmError *err=NULL;
 gfsmIOHandle *ioh=NULL;
CODE:
 ioh = gfsmperl_io_new_sv(str,0);
 RETVAL=gfsmxl_cascade_save_bin_handle(cscp->csc, ioh, &err);
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
