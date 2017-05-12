#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Stream.h>
#include <SWI-Prolog.h>

#include "opaque.h"
#include "callback.h"

static PL_blob_t perl_opaque;

static void
perl_opaque_acquire(atom_t a) {
    dSP;
    size_t len;
    PL_blob_t *type;
    SV *sv = PL_blob_data(a, &len, &type);
    assert(sv != NULL);
    assert(type == &perl_opaque);
    SvREFCNT_inc(sv);
}

static int
perl_opaque_release(atom_t a) {
    dSP;
    size_t len;
    PL_blob_t *type;
    SV *sv = PL_blob_data(a, &len, &type);
    assert(sv != NULL);
    assert(type == &perl_opaque);
    SvREFCNT_dec(sv);
    return TRUE;
}

static int
perl_opaque_write(IOSTREAM *s, atom_t a, int flags) {
    dSP;
    STRLEN l;
    size_t len;
    PL_blob_t *type;
    SV *sv = PL_blob_data(a, &len, &type);
    assert(sv != NULL);
    assert(type == &perl_opaque);
    Sfprintf(s, "<0x%x>", sv);
    return TRUE;
}

static PL_blob_t perl_opaque = {
    PL_BLOB_MAGIC,
    PL_BLOB_UNIQUE| PL_BLOB_NOCOPY,
    "perl_opaque",
    &perl_opaque_release,
    NULL, /* &perl_opaque_compare, */
    &perl_opaque_write,
    &perl_opaque_acquire,
};

int
pl_unify_perl_iopaque(pTHX_ term_t t, SV *o, AV *refs, AV *cells) {
    return pl_unify_perl_opaque(aTHX_ t, o, refs, cells);
}

int
pl_unify_perl_opaque(pTHX_ term_t t, SV *o, AV *refs, AV *cells) {
    dSP;
    SV *ref;
    SV *class;
    term_t op;
    static functor_t opaque_f;
    int ret = FALSE;

    if (!opaque_f)
	opaque_f = PL_new_functor(PL_new_atom(OPAQUE_FUNCTOR), 2);
    op = PL_new_term_ref();

    ENTER;
    SAVETMPS;

    ref = call_method__sv(aTHX_ o, "opaque_reference");
    class = call_method__sv(aTHX_ o, "opaque_class");

    if (PL_unify_blob(op, (void*)ref, 0, &perl_opaque) &&
	PL_unify_term(t,
		      PL_FUNCTOR, opaque_f,
		      PL_CHARS, SvPV_nolen(class),
		      PL_TERM, op))
	ret = TRUE;
    
    FREETMPS;
    LEAVE;

    return ret;
}

int
pl_get_perl_opaque(pTHX_ term_t t, SV** ref) {
    size_t len;
    PL_blob_t *type;
    term_t arg = PL_new_term_ref();

    if ( PL_get_arg(2, t, arg) &&
	 PL_get_blob(arg, (void **)ref, &len, &type) &&
	 type == &perl_opaque)
	return TRUE;
    return FALSE;
}
