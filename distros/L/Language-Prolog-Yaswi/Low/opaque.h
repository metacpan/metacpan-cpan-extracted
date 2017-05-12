#define OPAQUE_FUNCTOR "perl5_object"
/* #define OPAQUE_PREFIX "@perl_opaque_object:" */

int pl_get_perl_opaque(pTHX_ term_t t, SV** ref);


int pl_unify_perl_opaque(pTHX_ term_t t, SV *o, AV *refs, AV *cells);
int pl_unify_perl_iopaque(pTHX_ term_t t, SV *o, AV *refs, AV *cells);
