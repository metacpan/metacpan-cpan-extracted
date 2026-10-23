#ifndef EX_OP_H
#define EX_OP_H

#define MY_CXT_KEY "Ex::Op::_guts" XS_VERSION

typedef struct {
    OP      *next;
    CV      *cv;
    struct eo_op_s *e;
    COP     *oldcop;
    PMOP    *oldpm;
    PAD     *oldpad;
    SSize_t  oldfloor;
    I32      oldsaveix;
    I32      afterix;
    I32      markix;
    I32      cxix;
    I32      spcx;
    I32      oldsp;
    I32      runcx;
    CV      *oldruncv;
    PADOFFSET targ;
    U8       gimme;
    U8       oldgimme;
} eo_ret_t;

typedef struct {
    HV      *exports;
    eo_ret_t *ret;
    I32      ret_top;
    I32      ret_max;
    GV      *level_gv;
    GV      *verbose_gv;
    CV      *import_cv;
    CV      *export_cv;
    CV      *export_fail_cv;
} my_cxt_t;

#define EO_CACHE_SET   0
#define EO_CACHE_EXP   1
#define EO_CACHE_OK    2
#define EO_CACHE_NEXP  3
#define EO_CACHE_NOK   4

/* What registration learned about one sub. It hangs off the CV in ext
 * magic, so it goes where the CV goes, a thread clone included. */
typedef struct eo_op_s {
    OP        *root;
    OP        *entry;
    PADOFFSET *params;
    U16        nparams;
    bool       accepted;
    bool       has_return;
    bool       ctx_dep;
    bool       need_runcv;
    char      *why;
} eo_op_t;

#define EO_STRICT_KEY "Ex::Op/strict"

#endif
