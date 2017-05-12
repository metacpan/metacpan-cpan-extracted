#/*-*- Mode: C -*- */

MODULE = Gfsm::XL	PACKAGE = Gfsm::XL::Cascade::Lookup       PREFIX = gfsmxl_cascade_lookup_

##-- disable perl prototypes
PROTOTYPES: DISABLE

##=====================================================================
## Constructors etc.
##=====================================================================

##--------------------------------------------------------------
## Constructor: new()
gfsmxlCascadeLookupPerl*
new(char *CLASS, SV *csc_sv, gfsmWeight max_w=0, guint max_paths=1, guint max_ops=-1)
CODE:
 RETVAL = gfsmxl_perl_cascade_lookup_new(csc_sv, max_w, max_paths, max_ops);
 GFSMXL_DEBUG_EVAL(g_printerr("Gfsm::XL::Cascade::Lookup::new(): returning clp=%p, clp->cl=%p, clp->csc_sv=%p; clp->cl->csc=%p\n", RETVAL, RETVAL->cl, RETVAL->csc_sv, RETVAL->cl->csc);)
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## Destructor: DESTROY()
void
DESTROY(gfsmxlCascadeLookupPerl* clp)
CODE:
 GFSMXL_DEBUG_EVAL(g_printerr("Gfsm::XL::Cascade::Lookup::DESTROY(clp=%p : clp->cl=%p / csc_sv=%p, csc=%p)\n", clp, (clp ? clp->cl : NULL), (clp ? clp->csc_sv : NULL), (clp && clp->cl ? clp->cl->csc : NULL));)
 if (clp) gfsmxl_perl_cascade_lookup_free(clp);
 GFSMXL_BLOW_CHUNKS();


##=====================================================================
## High-level Access: Attributes
##=====================================================================

##--------------------------------------------------------------
## Attributes: cascade

SV*
_cascade_get(gfsmxlCascadeLookupPerl *clp)
CODE:
 RETVAL = sv_mortalcopy(clp->csc_sv);
 SvREFCNT_inc(RETVAL);
OUTPUT:
 RETVAL

void
_cascade_set(gfsmxlCascadeLookupPerl *clp, SV *cascade_sv)
CODE:
 gfsmxl_perl_cascade_lookup_set_cascade_sv(clp,cascade_sv);


##--------------------------------------------------------------
## Attributes: max_weight

gfsmWeight
_max_weight_get(gfsmxlCascadeLookupPerl *clp)
CODE:
 RETVAL = clp->cl->max_w;
OUTPUT:
 RETVAL

void
_max_weight_set(gfsmxlCascadeLookupPerl *clp, gfsmWeight w)
CODE:
 clp->cl->max_w = w;


##--------------------------------------------------------------
## Attributes: max_paths

guint
_max_paths_get(gfsmxlCascadeLookupPerl *clp)
CODE:
 RETVAL = clp->cl->max_paths;
OUTPUT:
 RETVAL

void
_max_paths_set(gfsmxlCascadeLookupPerl *clp, guint n)
CODE:
 clp->cl->max_paths = n;

##--------------------------------------------------------------
## Attributes: max_ops

guint
_max_ops_get(gfsmxlCascadeLookupPerl *clp)
CODE:
 RETVAL = clp->cl->max_ops;
OUTPUT:
 RETVAL

void
_max_ops_set(gfsmxlCascadeLookupPerl *clp, guint n)
CODE:
 clp->cl->max_ops = n;


##--------------------------------------------------------------
## Attributes: n_ops

guint
_n_ops_get(gfsmxlCascadeLookupPerl *clp)
CODE:
 RETVAL = clp->cl->n_ops;
OUTPUT:
 RETVAL

void
_n_ops_set(gfsmxlCascadeLookupPerl *clp, guint n)
CODE:
 clp->cl->n_ops = n;


##=====================================================================
## Operations
##=====================================================================

##--------------------------------------------------------------
## Operations: reset

void
reset(gfsmxlCascadeLookupPerl *clp)
CODE:
 gfsmxl_cascade_lookup_reset(clp->cl);

##--------------------------------------------------------------
## Operations: n-best lookup (FST)

void
_lookup_nbest(gfsmxlCascadeLookupPerl *clp, gfsmLabelVector *input, gfsmAutomaton *result)
CODE:
 gfsmxl_cascade_lookup_nbest(clp->cl, input, result);
CLEANUP:
 g_ptr_array_free(input,TRUE);

AV *
lookup_nbest_paths(gfsmxlCascadeLookupPerl *clp, gfsmLabelVector *input)
PREINIT:
 gfsmxlPathArray *paths_a;
CODE:
 paths_a = gfsmxl_cascade_lookup_nbest_paths(clp->cl, input, NULL);
 RETVAL  = gfsmxl_perl_patharray_to_av(paths_a);
 gfsmxl_patharray_free(paths_a);
OUTPUT:
 RETVAL
CLEANUP:
 g_ptr_array_free(input,TRUE);
