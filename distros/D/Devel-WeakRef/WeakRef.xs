/* Weak reference class. The constructor takes as argument a scalar
  which must be a reference. Returned is an opaque object which will
  return the original argument with the deref method, but does not tie
  up the reference count of the original. If all normal references to
  the original are removed, the object is collected, first voiding the
  pointer held by the weak reference.

  This type of object may be useful for implementing things like
  doubly-linked lists, trees, or any other kind of circular
  structures, provided you can decide which links to make weak; or it
  may be helpful in implementing heuristic cache tables, where weak
  refs can be the values in a hash table, e.g.

  In the current implementation, it can actually be used as a normal
  reference; when dereferenced with ${...}, it will produce the
  original hard object (in turn a reference). This fact may change;
  use the deref and empty methods for certainty. */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* Mark the cell as being voided. */

static int actual_free (SV *sv, MAGIC *mg) {
  /* We could truly undef it, but that is not even necessary: now it
     has no real flags on it. (!SvOK) */
  SV *cell=mg->mg_obj;
  MAGIC *mg2;
  SvROK_off(cell);
  mg2=mg_find(cell, '~');
  if (mg2) mg2->mg_obj=NULL;
  return 1;
}

static MGVTBL actual_vtbl = {NULL, NULL, NULL, NULL, actual_free};

static int cell_munge (SV *sv, MAGIC *mg) {
  /* No effort is made to undo the setting, just to avoid corrupting
     memory when it happens. */
  if (mg->mg_obj) SvREFCNT_inc(mg->mg_obj);
  sv_unmagic(sv, '~');
  croak("Illegal attempt to change the referent of a weak reference %p", sv);
  /* NOTREACHED */
  return 1;
}

static MGVTBL cell_vtbl = {NULL, cell_munge, NULL, cell_munge, NULL};

static char *baseclass="Devel::WeakRef";

static SV *get_cell(SV *actual) {
  MAGIC *	mg;
  SV *		cell;
  /* Find the already-existent magic cell if there is one. Note that
     since we are applying magic to an SV of unknown origin it is
     necessary to search exactly for what we want, keying off vtbl. */
  mg=mg_find(actual, '~');
  while (mg && (mg->mg_type != '~' || mg->mg_virtual != &actual_vtbl))
    mg=mg->mg_moremagic;
  if (mg) {
    /* All set. */
    cell=mg->mg_obj;
  } else {
    /* Add a new tilde entry with an SVRV pointing to ourself. */
    cell=newRV_noinc(actual); /* half-baked pointer */
    sv_magic(actual, cell, '~', baseclass, strlen(baseclass));
    mg=mg_find(actual, '~');
    mg->mg_virtual=&actual_vtbl;
    mg_magical(actual);
    /* Cell gets its own magic for protection. */
    sv_magic(cell, NULL, '~', baseclass, strlen(baseclass));
    mg=mg_find(cell, '~');
    mg->mg_virtual=&cell_vtbl;
    /* Keep an additional pointer into actual, but without refcounting it. */
    mg->mg_obj=actual;
    mg->mg_flags &= ~MGf_REFCOUNTED;
    mg_magical(cell);
  }
  /* Ref counting of everything else is completely normal. */
  return cell;
}

MODULE = Devel::WeakRef		PACKAGE = Devel::WeakRef

SV *
new(class, obj)
 char *		class
 SV *		obj
CODE:
 if (!SvROK(obj))
     croak("Object %p must be a reference type!", obj);
 RETVAL=sv_bless(newRV_inc(get_cell(SvRV(obj))), gv_stashpv(class, 1));
OUTPUT:
 RETVAL

SV *
deref(self)
 SV *		self
PREINIT:
 SV *		value;
CODE:
 if (!SvROK(self))
     croak("%p not a reference to deref!", self);
 if (!sv_isa(self, baseclass))
     croak("%p not a %s object!", self, baseclass);
 value=SvRV(self);
 /* We use the ROK flag to determine if the cell has been
    voided. Using NULL would have worked as well. */
 if (SvROK(value)) {
   RETVAL=newRV_inc(SvRV(value));
 } else {
   RETVAL=newSVsv(&sv_undef);
 }
OUTPUT:
 RETVAL

int
empty(self)
 SV *		self
CODE:
 if (!SvROK(self))
     croak("%p not a reference to empty!", self);
 if (!sv_isa(self, baseclass))
     croak("%p not a %s object!", self, baseclass);
 RETVAL=!SvROK(SvRV(self));
OUTPUT:
 RETVAL

MODULE = Devel::WeakRef		PACKAGE = Devel::WeakRef::Table

SV *
STORE(self, key, val)
 SV *		self
 SV *		key
 SV *		val
PREINIT:
 HV *hv=NULL;
 SV *cell;
CODE:
 if (!SvROK(self) ||
     !sv_isa(self, "Devel::WeakRef::Table")
     || SvTYPE(hv=(HV *)SvRV(self)) != SVt_PVHV) {
   croak("I (%p) am not a blessed ref to a hash!", self);
 }
 if (!SvROK(val)) croak("Can only store reference types, not %p", val);
 cell=SvREFCNT_inc(get_cell(SvRV(val)));
 /* Bless and discard that ref; we will return cell itself. */
 sv_bless(newRV_inc(cell), gv_stashpv("Devel::WeakRef", 1));
 hv_delete_ent(hv, key, G_DISCARD, 0); /* I'm cheap */
 hv_store_ent(hv, key, cell, 0);
 RETVAL=cell;
OUTPUT:
 RETVAL
