
#define MY_CXT_KEY "Language::Prolog::Yaswi::Low::_guts" XS_VERSION


typedef struct {
    /* int ok; */
    SV *depth;
    SV *converter;
    SV *qid;
    SV *query;
    AV *fids;
    GV *vars;
    GV *cells;
    GV *cache;
    int prolog_ok;
    int prolog_init;
} my_cxt_t;

#define c_depth     MY_CXT.depth
#define c_converter MY_CXT.converter
#define c_qid       MY_CXT.qid
#define c_query     MY_CXT.query
#define c_fids      MY_CXT.fids
#define c_vars      MY_CXT.vars
#define c_cells     MY_CXT.cells
#define c_cache     MY_CXT.cache
#define c_prolog_ok MY_CXT.prolog_ok
#define c_prolog_init MY_CXT.prolog_init


void init_cxt(pTHX);

void release_cxt(pTHX_ pMY_CXT);

my_cxt_t *get_MY_CXT(pTHX);

#define MY_dMY_CXT my_cxt_t *my_cxtp = get_MY_CXT(aTHX)

/* MY_dMY_CXT_accessor
 * ===================
 * Use this macro to call accessor in functions that take `pMY_CXT` parameter.
 * This is a no-op when `MULTIPLICITY` is defined.
 */
#ifndef INSIDE_CONTEXT_C
#ifndef MULTIPLICITY
#define MY_dMY_CXT_accessor MY_dMY_CXT
/* MY_CXT is used in combination with MY_dMY_CXT_accessor.
 *
 * Redefine to using the pointer because the static variable is not visible.
 */
#define MY_CXT (*my_cxtp)
#else
#define MY_dMY_CXT_accessor dNOOP
#endif /* MULTIPLICITY */
#endif /*INSIDE_CONTEXT_C */
