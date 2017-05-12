#ifndef PERL_JSONSL_H_
#define PERL_JSONSL_H_
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <limits.h>
/**
 * Default depth limit to use, if none supplied
 */
#define PLJSONSL_MAX_DEFAULT 512

/**
 * Key names for the information returned by
 * JSONpointer results
 */
#define PLJSONSL_INFO_KEY_PATH "Path"
#define PLJSONSL_INFO_KEY_VALUE "Value"
#define PLJSONSL_INFO_KEY_QUERY "JSONPointer"

/**
 * Names of various perl globs
 */
#define PLJSONSL_CLASS_NAME "JSON::SL"
#define PLJSONSL_BOOLEAN_NAME "JSON::SL::Boolean"
#define PLJSONSL_PLACEHOLDER_NAME "JSON::SL::Placeholder"

#define PLTUBA_CLASS_NAME "JSON::SL::Tuba"
#define PLTUBA_HKEY_NAME "_TUBA"


#if PERL_VERSION >= 10
#define PLJSONSL_HAVE_HV_COMMON
#else
#warning "You are using a Perl from the stone age. This code might work.."
#endif /* 5.10.0 */


/**
 * Extended fields for a stack state
 * sv: the raw SV (never a reference)
 * u_loc.idx / u_loc.key: the numerical index or the HE key, depending
 *  on parent type.
 * matchres: the result of the last match
 * matchjpr: the jsonsl_jpr_t object (assuming a successful match [COMPLETE] )
 */
#define JSONSL_STATE_USER_FIELDS \
    SV *sv; \
    union { \
        int idx; \
        HE *key; \
    } u_loc; \
    int matchres; \
    int uescapes; \
    jsonsl_jpr_t matchjpr;

/**
 * We take advantage of the JSONSL_API and make all symbols
 * non-exportable
 */
#define JSONSL_API static
#include "jsonsl/jsonsl.h"
#include "jsonsl/jsonsl.c"

/**
 * For threaded perls, this stores the THX/my_perl context
 * inside the object's pl_thx field. For non threaded perls,
 * this is a nop.
 */
#ifndef tTHX
#define tTHX PerlInterpreter*
#endif

#ifdef PERL_IMPLICIT_CONTEXT
#define PLJSONSL_dTHX(pjsn) \
    pTHX = (tTHX)pjsn->pl_thx
#define PLJSONSL_mkTHX(pjsn) \
    pjsn->pl_thx = my_perl;
#else
#define PLJSONSL_dTHX(pjsn)
#define PLJSONSL_mkTHX(pjsn)
#endif /* PERL_IMPLICIT_CONTEXT */


/*
 * This is the 'abstract base class' for both JSON::SL and JSON::SL::Tuba
 */
#define PLJSONSL_COMMON_FIELDS \
    /* The lexer */ \
    jsonsl_t jsn;  \
    /* Input buffer */ \
    SV *buf; \
    /* Start position of the buffer (relative to input stream) */ \
    size_t pos_min_valid; \
    /* Position of the beginning of the earlist of (SPECIAL,STRINGY) */ \
    size_t keep_pos; \
    /* Context for threaded Perls */ \
    void *pl_thx; \
    /* Stash for booleans */ \
    HV *stash_boolean; \
    /* Escape table */ \
    int escape_table[0x80];

/* These are the escapes we care about: */
#define PLJSONSL_ESCTBL_INIT(tbl) \
    memset(ESCTBL, 0, sizeof(ESCTBL)); \
    tbl['"'] = 1; \
    tbl['\\'] = 1; \
    tbl['/'] = 1; \
    tbl['b'] = 1; \
    tbl['n'] = 1; \
    tbl['r'] = 1; \
    tbl['f'] = 1; \
    tbl['u'] = 1; \
    tbl['t'] = 1;


typedef struct {
    PLJSONSL_COMMON_FIELDS

    /* Root perl data structure. This is either an HV* or AV* */
    SV *root;

    /**
     * "current" hash key. This is always a pointer to an HE* of an existing
     * hash entry, and thus should never be freed/destroyed directly.
     * This variable should only be non-null during until the next PUSH
     * callback
     */
    HE *curhk;

#ifndef PLJSONSL_HAVE_HV_COMMON
    /**
     * For older perls not exposing hv_common, we need a key sv.
     * make this as efficient as possible. Instead of instantiating a new
     * SV each time for hv_fetch_ent, we keep one cached, and change its
     * PV slot as needed. I am able to do this because I have looked at 5.8's
     * implementation for the hv_* methods in hv.c and unless the hash is magical,
     * the behavior is to simply extract the PV from the SV in the beginning
     * anyway.
     */
    SV *ksv;
    char *ksv_origpv;
#endif


    struct {
        int utf8; /** Set the SvUTF8 flag */
        int nopath; /** Don't include path context in results */
        int noqstr; /** Don't include original query string in results */
        int max_size; /** maximum input size (from JSON::XS) */
        /* ignore the jsonpointer settings and allow an 'iv-drip' of
         * objects to be returned via feed */
        int object_drip;

        /** Callback to invoke when root object is about to be destroyed */
        SV *root_callback;
    } options;

    /**
     * Private options
     */
    struct {
        /* whether this is the 'global' JSON::SL object used
         * for decode_json()
         */
        int is_global;
    } priv_global;

    /**
     * If we allocate a bunch of JPR objects, keep a reference to
     * them here in order to destroy them along with ourselves.
     */
    jsonsl_jpr_t *jprs;
    size_t njprs;

    /**
     * This is the 'result stack'
     */
    AV *results;

    /**
     * Escape preferences
     */
} PLJSONSL;


#define PLTUBA_XCALLBACK \
    JSONSL_XTYPE \
    X(DATA, 'c') \
    X(ERROR, '!') \
    X(JSON, 'D') \
    X(NUMBER, '=') \
    X(BOOLEAN, '?') \
    X(NULL, '~') \
    X(ANY, '.') \

typedef enum {
#define X(o,c) \
    PLTUBA_CALLBACK_##o = c,
    PLTUBA_XCALLBACK
#undef X
    PLTUBA_CALLBACK_blah
} pltuba_callback_type;

#define PLTUBA_ACTION_ON '>'


#define PLTUBA_DEFINE_XMETHGV
#include "srcout/tuba_dispatch_getmeth.h"
#undef PLTUBA_DEFINE_XMETHGV

/* These are stringified as the 'Info' keys */
#define PLTUBA_XPARAMS \
    X(Escaped) \
    X(Key) \
    X(Type) \
    X(Mode) \
    X(Value) \
    X(Index)


/**
 * This can be considered to be a 'subset' of the
 * PLJSONSL structure, but with some slight subtleties and
 * differences.
 */

struct pltuba_param_entry_st {
    HE *he;
    SV *sv;
};

typedef struct {
    PLJSONSL_COMMON_FIELDS

    /* When we invoke a callback, instead of re-creating the
     * mortalized rv each time, we just keep a static reference
     * to ourselves
     */
    SV *selfrv;

    /* This is last known stash for our methods.
     * In the rare event that someone decides to rebless
     * us into a different class, we compare and swap out
     * in favor of the new one (SvSTASH(SvRV(tuba->selfrv)));
     */
    HV *last_stash;

    /* set by hkey and string callbacks */
    int shift_quote;

    /* Options */
    struct {
        int utf8;
        int no_cache_mro;
        int accum_kv;
        int cb_unified;
        int allow_unhandled;
    } options;

#define PLTUBA_METHGV_STRUCT
#include "srcout/tuba_dispatch_getmeth.h"
#undef PLTUBA_METHGV_STRUCT
    /* The accumulators */
    SV *accum;
    SV *kaccum;

    /**
     * The following structures contain registers for the
     * HEs which are hash entries for the info hash, and the
     * corresponding SVs which they contain.
     */
    struct {
#define X(vname) \
    struct pltuba_param_entry_st pe_##vname;
        PLTUBA_XPARAMS
#undef X
    } p_ents;

    /* Our info hash, and its reference */
    HV *paramhv;
    SV *paramhvrv;

    /* Table of various callbacks to invoke */
    int accum_options[0x100];

} PLTUBA;

/**
 * These macros manipulate the static entries within the hash
 * which is passed into callbacks.
 * There are two primary variables to work with:
 * 1) The actual static SV which contains the value
 * 2) The HE which points to the SV
 *
 * And three operations
 * 1) Assigning the value to the SV
 * 2) Tying the HE with the SV, so a lookup on the hash
 * entry yields the SV
 * 3) Decoupling the HE and the SV, so the SV remains allocated
 * but the HE will now point to &PL_sv_placeholder and not yield
 * a result.
 */
#define PLTUBA_PARAM_FIELD(tuba, b) \
    (tuba->p_ents.pe_##b)

/**
 * Assign an SV to the named field. The HE is made to point to the SV
 */
#define PLTUBA_SET_PARAMFIELDS_sv(tuba, field, sv) \
    HeVAL(PLTUBA_PARAM_FIELD(tuba,field).he) = sv;

/**
 * Convenience macro which assigns the SV to the HE, and then sets
 * the IVX slot.
 */
#define PLTUBA_SET_PARAMFIELDS_iv(tuba, field, iv) \
        /* assign the IV */ \
        assert(PLTUBA_PARAM_FIELD(tuba,field).sv); \
        assert(SvIOK(PLTUBA_PARAM_FIELD(tuba,field).sv)); \
    SvIVX(PLTUBA_PARAM_FIELD(tuba, field).sv) = iv; \
        /* set the he's value to the just-assigned sv */ \
    PLTUBA_SET_PARAMFIELDS_sv(tuba, field, PLTUBA_PARAM_FIELD(tuba,field).sv)

#define PLTUBA_SET_PARAMFIELDS_dv(tuba, field, c) \
    PLTUBA_SET_PARAMFIELDS_iv(tuba, field, c); \
    *SvPVX(PLTUBA_PARAM_FIELD(tuba,field).sv) = (char)c; \

/**
 * Sets the HE to point to &PL_sv_placeholder.
 */
#define PLTUBA_RESET_PARAMFIELD(tuba, field) \
    HeVAL(PLTUBA_PARAM_FIELD(tuba, field).he) = &PL_sv_placeholder;


#endif /* PERL_JSONSL_H_ */
