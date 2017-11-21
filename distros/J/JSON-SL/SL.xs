#include "perl-jsonsl.h"
#include "jsonxs_inline.h"

/*
 * JSON::SL, JSON::SL::Boolean
 */
#define MY_CXT_KEY "JSON::SL::_guts" XS_VERSION

typedef struct {
    PLJSONSL* quick;
    HV *stash_obj;
    HV *stash_boolean;
    HV *stash_tuba;
} my_cxt_t;
START_MY_CXT

static int PLJSONSL_Escape_Table_dfl[0x80];
#define ESCTBL PLJSONSL_Escape_Table_dfl

#define PLJSONSL_CROAK_USAGE(m) \
    die("JSON::SL: %s %s", GvNAME(CvGV(cv)), m)


#ifdef PLJSONSL_HAVE_HV_COMMON
#define storeget_he(pjsn, hv, buf, len, value, is_utf8) \
    hv_common((HV*)(hv), NULL, /*KEYSV*/ \
        buf, len, \
        ((is_utf8)?HVhek_UTF8:0), /*flags*/\
        HV_FETCH_ISSTORE, /*action*/ \
        value, \
        0 /* HASH (tell perl to compute) */)

#define delete_he(pjsn,hv,he) delete_he_THX(aTHX_ pjsn, hv, he)
static void
delete_he_THX(pTHX_ const PLJSONSL *dummy, HV* hv, HE* he)
{
    char *kbuf;
    STRLEN klen;
    int is_utf8;

    kbuf = HePV(he, klen);
    is_utf8 = HeUTF8(he);
    hv_common(hv, NULL, /* KEYSV */
        kbuf, klen,
        (is_utf8 ? HVhek_UTF8 : 0), /*flags*/
        HV_DELETE|G_DISCARD, /*action*/
        NULL, /* value */
        HeHASH(he) /*hash value - already computed */);
}

#define PLJSONSL_INIT_KSV(blah)
#define PLJSONSL_DESTROY_KSV(blah)


#else
/* probably very dangerous, but the beginning of hv_store_common
 * looks quite simple...
 */

#define CLOBBER_PV(sv,buf,len) \
    SvCUR_set(sv, len); \
    SvPVX(sv) = buf; \
    SvUTF8_off(sv);

#define UNCLOBBER_PV(sv) \
    SvCUR_set(sv, 0); \
    SvPVX(sv) = NULL; \

#define PLJSONSL_INIT_KSV(pjsn) \
    pjsn->ksv = newSV(16); \
    pjsn->ksv_origpv = SvPVX(pjsn->ksv); \
    SvLEN_set(pjsn->ksv, 0); \
    SvPOK_on(pjsn->ksv);

#define PLJSONSL_DESTROY_KSV(pjsn) \
        CLOBBER_PV(pjsn->ksv, pjsn->ksv_origpv, 0); \
        SvREFCNT_dec(pjsn->ksv);

#define storeget_he(...) storeget_he_THX(aTHX_ __VA_ARGS__)
static HE*
storeget_he_THX(pTHX_ PLJSONSL *pjsn, HV *hv, const char *buf, size_t len,
                SV *value, int is_utf8)
{
    HE *ret;

    CLOBBER_PV(pjsn->ksv, buf, len);
    if (is_utf8) {
        SvUTF8_on(pjsn->ksv);
    }
    ret = hv_store_ent(hv, pjsn->ksv, value, 0);
    UNCLOBBER_PV(pjsn->ksv);
    return ret;
}

#define delete_he(...) delete_he_THX(aTHX_ __VA_ARGS__)
static void
delete_he_THX(pTHX_ PLJSONSL *pjsn, HV *hv, HE* he)
{
    char *kbuf;
    STRLEN klen;
    kbuf = HePV(he, klen);

    CLOBBER_PV(pjsn->ksv, buf, len);
    if (HeUTF8(he)) {
        SvUTF8_on(pjsn->ksv);
    }
    (void)hv_delete_ent(hv, pjsn->ksv, G_DISCARD, HeHASH(he));
    UNCLOBBER_PV(pjsn->ksv);
}

#endif /* HAVE_HV_COMMON */


#define REFDEC_FIELD(pjsn, fld) \
    if (pjsn->fld != NULL) \
    { \
        SvREFCNT_dec(pjsn->fld); \
        pjsn->fld = NULL; \
    } \



#define GET_STATE_BUFFER(pjsn, pos) \
    (char*)(SvPVX(pjsn->buf) + (pos - pjsn->pos_min_valid))

#define PLJSONSL_NEWSVUV_fast(sv, val) \
    sv = newSV(0); \
    sv_upgrade(sv, SVt_IV); \
    SvIOK_only(sv); \
    SvUVX(sv) = val;

/**
 * These 'common' functions are generic enough to work
 * on all objects wiht a common pjsn head.
 */

#define pljsonsl_common_mknumeric(s,b,n) \
        pljsonsl_common_mknumeric_THX(aTHX_ s,b,n)
static SV *
pljsonsl_common_mknumeric_THX(pTHX_
                              struct jsonsl_state_st *state,
                              const char *buf,
                              size_t nbuf)
{
#define die_numeric(err) \
    die("JSON::SL - Malformed number (%s)", err);

    SV *newsv;
    switch (state->special_flags) {
    /* Simple signed/unsigned numbers, no exponents or fractions to worry about */
    case JSONSL_SPECIALf_UNSIGNED:
        if (nbuf == 1) {
            PLJSONSL_NEWSVUV_fast(newsv, state->nelem);
            break;
        } /* else, ndigits > 1 */
        if (*buf == '0') { die_numeric("leading zero for non-fraction"); }
        if (nbuf < (UV_DIG-1)) {
            PLJSONSL_NEWSVUV_fast(newsv, state->nelem);
            break;
        } /* else, potential overflow */
        newsv = jsonxs_inline_process_number(buf);
        break;

    case JSONSL_SPECIALf_SIGNED:
        nbuf--;
        if (nbuf == 0) { die_numeric("found lone '-'"); }
        if (nbuf > 1 && buf[1] == '0') {
            die_numeric("Leading 0 after '-'");
        }
        if (nbuf < (IV_DIG-1)) {
            newsv = newSViv(-((IV)state->nelem));
            break;
        } /*else */
        newsv = jsonxs_inline_process_number(buf);
        break;

    default:
        if (state->special_flags & JSONSL_SPECIALf_NUMNOINT) {
            newsv = jsonxs_inline_process_number(buf);
        }
        break;
    }
    return newsv;
#undef die_numeric
}

#define pljsonsl_common_mkboolean(pjsn_head, value) \
    pljsonsl_common_mkboolean_THX(aTHX_ pjsn_head, value)

static SV *
pljsonsl_common_mkboolean_THX(pTHX_
                              PLJSONSL *pjsn_head,
                              jsonsl_special_t specialf)
{
    SV *retsv, *ivsv;
    ivsv = newSViv(specialf == JSONSL_SPECIALf_TRUE);
    retsv = newRV_noinc(ivsv);
    sv_bless(retsv, pjsn_head->stash_boolean);
    return retsv;
}

#define pljsonsl_common_initialize(mycxt, pjsn_head, max_levels) \
    pljsonsl_common_initialize_THX(aTHX_ mycxt, pjsn_head, max_levels)

static void
pljsonsl_common_initialize_THX(pTHX_
                               my_cxt_t *mycxt,
                               PLJSONSL *pjsn_head,
                               size_t max_levels)
{
    pjsn_head->jsn = jsonsl_new(max_levels+2);
    pjsn_head->jsn->data = pjsn_head;
    pjsn_head->stash_boolean = mycxt->stash_boolean;
    PLJSONSL_mkTHX(pjsn_head);
    memcpy(pjsn_head->escape_table, ESCTBL, sizeof(ESCTBL));
}


#define process_special(pjsn,st) process_special_THX(aTHX_ pjsn,st)
static inline void
process_special_THX(pTHX_
                    PLJSONSL *pjsn,
                    struct jsonsl_state_st *state)
{
    SV *newsv;
    char *buf = GET_STATE_BUFFER(pjsn, state->pos_begin);
size_t poscur = pjsn->jsn->pos;

    switch (state->special_flags) {
    /* might look redundant, but is most common, so it's first */
    case JSONSL_SPECIALf_UNSIGNED:
    case JSONSL_SPECIALf_SIGNED:
        newsv = pljsonsl_common_mknumeric(state,
                                          buf,
                                          poscur - state->pos_begin);
        break;

    case JSONSL_SPECIALf_TRUE:
    case JSONSL_SPECIALf_FALSE:
        newsv = pljsonsl_common_mkboolean(pjsn, state->special_flags);
        break;
    case JSONSL_SPECIALf_NULL:
        newsv = newSV(0);
        break;
    default:
        newsv = pljsonsl_common_mknumeric(state,
                                          buf,
                                          poscur - state->pos_begin);
        break;
    }

    if (newsv == NULL) {
        warn("Buffer is %p", buf);
        warn("Length is %lu", poscur - state->pos_begin);
        warn("Special flag is %d", state->special_flags);
        die("WTF!");
    }

    state->sv = newsv;
    return;
}

/**
 * This is called to clean up any quotes, and possibly
 * handle \u-escapes in the future
 */
#define process_string(pjsn,st) process_string_THX(aTHX_ pjsn,st)
static void
process_string_THX(pTHX_
                   PLJSONSL* pjsn,
                   struct jsonsl_state_st *state)
{
    SV *retsv;
    char *buf = GET_STATE_BUFFER(pjsn, state->pos_begin);
    size_t buflen;
    size_t poscur = pjsn->jsn->pos;
    buf++;
    buflen = (poscur - state->pos_begin) - 1;
    retsv = newSV(buflen);

    sv_upgrade(retsv, SVt_PV);
    SvPOK_on(retsv);

    if (state->nescapes == 0) {
        SvCUR_set(retsv, buflen);
        memcpy(SvPVX(retsv), buf, buflen);
    } else {
        jsonsl_error_t err;
        jsonsl_special_t flags;
        size_t newlen;
        newlen = jsonsl_util_unescape_ex(buf,
                                         SvPVX(retsv),
                                         buflen,
                                         pjsn->escape_table,
                                         &flags,
                                         &err, NULL);
        if (!newlen) {
            SvREFCNT_dec(retsv);
            die("Could not unescape string: %s", jsonsl_strerror(err));
        }
        /* Shrink the buffer to the effective new size */
        SvCUR_set(retsv, newlen);
        if (flags & JSONSL_SPECIALf_NONASCII) {
            SvUTF8_on(retsv);
        }
    }

    state->sv = retsv;
    if (pjsn->options.utf8) {
        SvUTF8_on(state->sv);
    }
}


/**
 * This function will try and determine if the current
 * item is a matched result (which should be returned to
 * the user).
 * If this is a complete match, the SV (along with relevant info)
 * will be pushed to the result stack and return true. Returns
 * false otherwise.
 */
#define object_mkresult(pjsn,st_p,st_c) object_mkresult_THX(aTHX_ pjsn, st_p,st_c)
static inline int
object_mkresult_THX(pTHX_
                    PLJSONSL *pjsn,
                    struct jsonsl_state_st *parent,
                    struct jsonsl_state_st *child)
{
#define STORE_INFO(b, v) \
    (void)hv_stores(info_hv, PLJSONSL_INFO_KEY_##b, v)
    HV *info_hv;

    if (pjsn->options.object_drip == 0 &&
        (child->matchres != JSONSL_MATCH_COMPLETE || child->type == JSONSL_T_HKEY)) {
        return 0;
    }

    info_hv = newHV();
    if (SvTYPE(child->sv) == SVt_PVHV || SvTYPE(child->sv) == SVt_PVAV) {
        STORE_INFO(VALUE, newRV_noinc(child->sv));
    } else {
        STORE_INFO(VALUE, child->sv);
    }

    if (pjsn->options.noqstr == 0 && pjsn->options.object_drip == 0) {
        STORE_INFO(QUERY, newSVpvn_share(child->matchjpr->orig,
                                         child->matchjpr->norig, 0));
    }

    if (pjsn->options.nopath == 0) {
        SV *pathstr;
        int ii;
        pathstr = newSVpvs("/");
        for (ii = 2; ii <= (child->level); ii++) {
            struct jsonsl_state_st *cur = pjsn->jsn->stack + ii;
            struct jsonsl_state_st *prev = jsonsl_last_state(pjsn->jsn, cur);
            if (prev->type == JSONSL_T_LIST) {
                sv_catpvf(pathstr, "%d/", cur->u_loc.idx);
            } else {
                char *kbuf;
                STRLEN klen;
                assert(cur->u_loc.key);
                kbuf = HePV(cur->u_loc.key, klen);
                sv_catpvn(pathstr, kbuf, klen);
                sv_catpvs(pathstr, "/");
                if (HeKUTF8(cur->u_loc.key)) {
                    SvUTF8_on(pathstr);
                }
            }
        }
        /* Trim the trailing '/' from the path string */
        if (SvCUR(pathstr) != 1) {
            SvCUR_set(pathstr, SvCUR(pathstr)-1);
        }
        STORE_INFO(PATH, pathstr);
    }

    /**
     * For the sake of allowing inspection of the object tree, array
     * and hash types are always added to their parents, even if they
     * are a complete match to be removed from the stack.
     */
    if (parent && parent->sv) {
        SvREADONLY_off(parent->sv);
        SvREFCNT_inc_simple_void_NN(child->sv);
        if (parent->type == JSONSL_T_LIST) {
            SV *popped_sv = av_pop((AV*)parent->sv);
            if (popped_sv) {
                SvREFCNT_dec(popped_sv);
            }
        } else {
            HE* child_he = child->u_loc.key;
            SvREADONLY_off(HeVAL(child_he));
            delete_he(pjsn, (HV*)parent->sv, child_he);
#if 0
            /* for perls with hv_common, the above should be a macro for this: */
            hv_common((HV*)parent->sv,
                      NULL, kbuf, klen,
                      0, /*maybe HVhek_UTF8?*/
                      HV_DELETE|G_DISCARD ,
                      NULL,
                      HeHASH(child->u_loc.key));
#endif
            child->u_loc.key = NULL;
        }

        SvREADONLY_on(parent->sv);
        SvREADONLY_off(child->sv);
    }

    av_push(pjsn->results, newRV_noinc((SV*)info_hv));
    return 1;
#undef STORE_INFO
}


/**
 * Because we only want to maintain 'complete' elements, for
 * strings we ensure that their SVs do not get created until
 * the entire string is done (as a partial string would
 * not be of much use to the user anyway).
 * The opposite is true of hashes and arrays, which we create
 * immediately.
 */
static void body_push_callback(jsonsl_t jsn,
                               jsonsl_action_t action,
                               register struct jsonsl_state_st *state,
                               const char *at)
{
    struct jsonsl_state_st *parent;
    SV *newsv;
    char *mkey;
    size_t mnkey;
    register PLJSONSL *pjsn = (PLJSONSL*)jsn->data;
    PLJSONSL_dTHX(pjsn);

    /* Reset the position first */

    pjsn->keep_pos = state->pos_begin;

    parent = jsonsl_last_state(jsn, state);
    /* Here we set up parent positioning variables.. */
    if (parent->type == JSONSL_T_OBJECT) {
        if (state->type == JSONSL_T_HKEY) {
            return;
        }
        assert(pjsn->curhk);
        mkey = HeKEY(pjsn->curhk);
        mnkey = HeKLEN(pjsn->curhk);
        /**
         * Set the HE of our current value to the current HK, and then
         * remove curhk's visibility.
         */
        state->u_loc.key = pjsn->curhk;
        pjsn->curhk = NULL;
    } else {
        state->u_loc.idx = parent->nelem - 1;
        mkey = NULL;
        mnkey = state->u_loc.idx;
    }

    if (parent->matchres == JSONSL_MATCH_POSSIBLE) {
        state->matchjpr = jsonsl_jpr_match_state(jsn, state, mkey, mnkey,
                                                 &state->matchres);
    } else {
        state->matchjpr = NULL;
        state->matchres = JSONSL_MATCH_NOMATCH;
    }

    /**
     * Ignore warnings about uninitialized newsv variable.
     */
    if (!JSONSL_STATE_IS_CONTAINER(state)) {
        return; /* nothing more to do here. String types are added at POP */
    }

    if (state->type == JSONSL_T_OBJECT) {
        newsv = (SV*)newHV();
    } else if (state->type == JSONSL_T_LIST) {
        newsv = (SV*)newAV();
    } else {
        die("WTF");
    }

    SvREADONLY_on(newsv);
    if (parent->type == JSONSL_T_LIST) {
        SvREADONLY_off(parent->sv);
        av_push((AV*)parent->sv, newRV_noinc(newsv));
        SvREADONLY_on(parent->sv);
    } else {
        /* we have the HE. */
        HeVAL(state->u_loc.key) = newRV_noinc(newsv);
        SvREADONLY_on(HeVAL(state->u_loc.key));
    }

    state->sv = newsv;
}

/**
 * Creates a new HE*. We use this HE later on using HeVAL to assign the value.
 */

#define create_hk(pjsn,st_c,st_p) create_hk_THX(aTHX_ pjsn,st_c,st_p)
static void
create_hk_THX(pTHX_ PLJSONSL *pjsn,
              struct jsonsl_state_st *state,
              struct jsonsl_state_st *parent)
{
    char *buf = GET_STATE_BUFFER(pjsn, state->pos_begin);
    size_t poscur = pjsn->jsn->pos;
    STRLEN len = (poscur - state->pos_begin)-1;

    assert(pjsn->curhk == NULL);
    buf++;

    SvREADONLY_off(parent->sv);

    if (state->nescapes) {
        /* we have escapes within a key. rare, but allowable. No choice
         * but to allocate a new buffer for it
         */

        /* This sets state->sv to the key sv. would be nice if there was a cleaner
         * path to this
         */
        process_string(pjsn, state);
        pjsn->curhk = hv_store_ent((HV*)parent->sv, state->sv, &PL_sv_undef, 0);
        SvREFCNT_dec(state->sv);
        state->sv = NULL;
    } else {

        /**
         * Fast path, no copying to new SV.
         * We need to store &PL_sv_undef first to fool hv_common
         * into thinking we're not doing anything special. Then
         * we switch it out to &PL_sv_placeholder so it doesn't appear
         * visible.
         */
        pjsn->curhk = storeget_he(pjsn, parent->sv, buf, len, &PL_sv_undef,
            /*determine if UTF8: */
            pjsn->options.utf8 || state->special_flags == JSONSL_SPECIALf_NONASCII);
#if 0
        /* which is really this: */
        pjsn->curhk = hv_common((HV*)parent->sv, /* HV*/
                                NULL, /* keysv */
                                buf, len,
                                0, /* flags. Maybe setting utf8 */
                                HV_FETCH_ISSTORE, /*action*/
                                &PL_sv_undef, /*value*/
                                0);
#endif
    }

    HeVAL(pjsn->curhk) = &PL_sv_placeholder;
    SvREADONLY_on(parent->sv);
}

/* forward-declare initial state handler */
static void initial_callback(jsonsl_t jsn,
                             jsonsl_action_t action,
                             struct jsonsl_state_st *state,
                             const char *at);

/**
 * In this callback we ensure to clean up our strings and push it
 * into the parent SV
 */
static void body_pop_callback(jsonsl_t jsn,
                              jsonsl_action_t action,
                              register struct jsonsl_state_st *state,
                              const char *at)
{
    /* Ending of an element */
    struct jsonsl_state_st *parent = jsonsl_last_state(jsn, state);
    register PLJSONSL *pjsn = (PLJSONSL*)jsn->data;
    PLJSONSL_dTHX(pjsn);

#define INSERT_STRING \
    if (parent && object_mkresult(pjsn, parent, state) == 0) { \
        SvREADONLY_off(parent->sv); \
        if (parent->type == JSONSL_T_OBJECT) { \
            assert(state->u_loc.key); \
            HeVAL(state->u_loc.key) = state->sv; \
        } else { \
            av_push((AV*)parent->sv, state->sv); \
        } \
        SvREADONLY_on(parent->sv); \
    } \

    if (state->type == JSONSL_T_STRING) {
        process_string(pjsn, state);
        INSERT_STRING;
    } else if (state->type == JSONSL_T_HKEY) {
        assert(parent->type == JSONSL_T_OBJECT);
        create_hk(pjsn, state, parent);
    } else if (state->type == JSONSL_T_SPECIAL) {
        assert(state->special_flags);
        process_special(pjsn, state);
        INSERT_STRING;
    } else {
        SvREADONLY_off(state->sv);
        object_mkresult(pjsn, parent, state);
    }

    #undef INSERT_STRING

    if (state->sv == pjsn->root) {
        if (pjsn->njprs == 0 && pjsn->options.object_drip == 0) {
            av_push(pjsn->results, newRV_noinc(pjsn->root));
        } /* otherwise, already pushed */
        pjsn->root = NULL;
        jsn->action_callback_PUSH = initial_callback;
    }

    state->u_loc.idx = -1;
    state->sv = NULL;
    pjsn->keep_pos = 0;

}

static int error_callback(jsonsl_t jsn,
                           jsonsl_error_t err,
                           struct jsonsl_state_st *state,
                           char *at)
{
    PLJSONSL *pjsn = (PLJSONSL*)jsn->data;
    PLJSONSL_dTHX(pjsn);
    /**
     * TODO: allow option for user-defined recovery function
     */

    die("JSON::SL - Got error %s at position %lu", jsonsl_strerror(err), jsn->pos);
    return 0;
}

static void invoke_root_cb(PLJSONSL *pjsn)
{
    PLJSONSL_dTHX(pjsn);
    if (!pjsn->options.root_callback) {
        return;
    }
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_inc(pjsn->root)));
    PUTBACK;
    call_sv(pjsn->options.root_callback, G_DISCARD);
    FREETMPS;
    LEAVE;
}

static void initial_callback(jsonsl_t jsn,
                             jsonsl_action_t action,
                             struct jsonsl_state_st *state,
                             const char *at)
{
    PLJSONSL *pjsn = (PLJSONSL*)jsn->data;
    PLJSONSL_dTHX(pjsn);

    assert(action == JSONSL_ACTION_PUSH);
    if (state->type == JSONSL_T_LIST) {
        pjsn->root = (SV*)newAV();
    } else if (state->type == JSONSL_T_OBJECT) {
        pjsn->root = (SV*)newHV();
    } else {
        die("Found type %s as root element", jsonsl_strtype(state->type));
    }

    if (pjsn->options.root_callback) {
        invoke_root_cb(pjsn);
    }

    state->sv = pjsn->root;
    jsn->action_callback = NULL;
    jsn->action_callback_PUSH = body_push_callback;
    jsn->action_callback_POP = body_pop_callback;
    jsonsl_jpr_match_state(jsn, state, NULL, 0, &state->matchres);
    /* Mark root element as read only */
    SvREADONLY_on(pjsn->root);
}

#define CHECK_MAX_SIZE(pjsn,input) \
    if (pjsn->options.max_size && SvCUR(input) > pjsn->options.max_size) { \
        die("JSON::SL - max_size is %lu, but input is %lu bytes", \
            pjsn->options.max_size, SvCUR(input)); \
    }

#define pljsonsl_feed_incr(pjsn,str) pljsonsl_feed_incr_THX(aTHX_ pjsn,str)
static void
pljsonsl_feed_incr_THX(pTHX_ PLJSONSL* pjsn, SV *input)
{
    size_t start_pos = pjsn->jsn->pos;
    STRLEN cur_len = SvCUR(pjsn->buf);

    if (!SvPOK(input)) {
        die("Input is not a string");
    }

    CHECK_MAX_SIZE(pjsn, input)

    pjsn->pos_min_valid = pjsn->jsn->pos - cur_len;
    if (SvUTF8(input)) {
        pjsn->options.utf8 = 1;
    }
    sv_catpvn(pjsn->buf, SvPVX_const(input), SvCUR(input));
    jsonsl_feed(pjsn->jsn,
                SvPVX_const(pjsn->buf) + (SvCUR(pjsn->buf)-SvCUR(input)),
                SvCUR(input));
    /**
     * Callbacks may detect the beginning of a string, in which case
     * we need to ensure the continuity of the string. In this case
     * pos_keep is set to the position of the input stream (not the SV *input,
     * but rather jsn->pos) from which we should begin buffering data.
     *
     * Now we might need to chop. The amount of bytes to chop is the
     * difference between start_pos and the keep_pos
     * variable (if any)
     */
    if (pjsn->keep_pos == 0) {
        SvCUR_set(pjsn->buf, 0);
    } else if (pjsn->keep_pos > start_pos) {
        sv_chop(pjsn->buf, SvPVX_const(pjsn->buf) + (pjsn->keep_pos - start_pos));
    }
}

static PLJSONSL*
pljsonsl_get_and_initialize_global(pTHX)
{
    dMY_CXT;
    PLJSONSL *pjsn;
    if (MY_CXT.quick == NULL) {
        Newxz(pjsn, 1, PLJSONSL);
        pljsonsl_common_initialize(&MY_CXT, pjsn, PLJSONSL_MAX_DEFAULT-1);
        pjsn->priv_global.is_global = 1;
        PLJSONSL_INIT_KSV(pjsn);
        MY_CXT.quick = pjsn;
    }

    pjsn = MY_CXT.quick;
    jsonsl_reset(pjsn->jsn);
    jsonsl_enable_all_callbacks(pjsn->jsn);
    pjsn->jsn->error_callback = error_callback;
    pjsn->jsn->action_callback_PUSH = initial_callback;
    pjsn->results = (AV*)sv_2mortal((SV*)newAV());
    return pjsn;
}

#define pljsonsl_feed_oneshot(pjsn,str) pljsonsl_feed_oneshot_THX(aTHX_ pjsn,str)
static void
pljsonsl_feed_oneshot_THX(pTHX_ PLJSONSL* pjsn, SV *input)
{
    if (!SvPOK(input)) {
        die("Input is not a string");
    }

    if (SvUTF8(input)) {
        pjsn->options.utf8 = 1;
    }
    CHECK_MAX_SIZE(pjsn, input);
    pjsn->buf = input;
    jsonsl_feed(pjsn->jsn, SvPVX_const(input), SvCUR(input));
    pjsn->buf = NULL;
    pjsn->options.utf8 = 0;
    /* the current root is never in the result stack..
     * so mortalizing it won't hurt anyone.
     */
}

/**
 * Takes an array ref (or list?) of JSONPointer strings and converts
 * them to JPR objects. Dies on error
 */
#define pljsonsl_set_jsonpointer(pjsn,jprstr) \
    pljsonsl_set_jsonpointer_THX(aTHX_ pjsn,jprstr)
static void
pljsonsl_set_jsonpointer_THX(pTHX_ PLJSONSL *pjsn, AV *paths)
{
    jsonsl_jpr_t *jprs;
    jsonsl_error_t err;
    int ii;
    int max = av_len(paths)+1;
    const char *diestr, *pathstr;

    if (!max) {
        die("No paths given!");
    }

    Newxz(jprs, max, jsonsl_jpr_t);

    for (ii = 0; ii < max; ii++) {
        SV **tmpsv = av_fetch(paths, ii, 0);
        if (tmpsv == NULL || SvPOK(*tmpsv) == 0) {
            diestr = "Found empty path";
            goto GT_ERR;
        }
        jprs[ii] = jsonsl_jpr_new(SvPVX_const(*tmpsv), &err);
        if (jprs[ii] == NULL) {
            pathstr = SvPVX_const(*tmpsv);
            goto GT_ERR;
        }
    }

    jsonsl_jpr_match_state_init(pjsn->jsn, jprs, max);
    pjsn->jprs = jprs;
    pjsn->njprs = max;
    return;

    GT_ERR:
    for (ii = 0; ii < max; ii++) {
        if (jprs[ii] == NULL) {
            break;
        }
        jsonsl_jpr_destroy(jprs[ii]);
    }
    Safefree(jprs);
    if (pathstr) {
        die("Couldn't convert %s to jsonpointer: %s", pathstr, jsonsl_strerror(err));
    } else {
        die(diestr);
    }
}





/**
 * JSON::SL::Tuba functions.
 * In case you haven't wondered already, 'Tuba' is a play on 'SAX'.
 */


/**
 * This is our quick version of MRO caching. Maybe I'll swap this out
 * for something which already exists (as I get the feeling I've reinveted
 * the wheel here.
 * namep is populated with the handler name, gvp is a pointer to the GV**
 * - or an offset into the PLTUBA's methgv structure.
 */
static void
pltuba_get_method_info(PLTUBA *tuba,
                       jsonsl_action_t action,
                       pltuba_callback_type cbtype,
                       GV ***gvpp,
                       const char **namep)
{
    GV **methgvp = NULL;
    const char *methname = NULL;
    cbtype &= 0x7f;

    if (tuba->options.cb_unified) {
        methname = "on_any";
        methgvp = &tuba->methgv.on_any;
        goto GT_RETASGN;
    }
#define PLTUBA_METH_GETMETH
#include "srcout/tuba_dispatch_getmeth.h"
#undef PLTUBA_METH_GETMETH
    GT_RETASGN:
    if (gvpp) {
        *gvpp = methgvp;
    }
    if (namep) {
        *namep = methname;
    }
}

static void
pltuba_invalidate_gvs_THX(pTHX_ PLTUBA *tuba)
{

#define X(action,type) \
    REFDEC_FIELD(tuba, methgv.action## _ ##type)

    PLTUBA_XMETHGV
#undef X
}

/**
 * Maps a 'jsonsl' type to a tuba callback type.
 */
static pltuba_callback_type
convert_to_tuba_cbt(struct jsonsl_state_st *state)
{
    if (state->type != JSONSL_T_SPECIAL) {
        return state->type;
    }
    if (state->special_flags & JSONSL_SPECIALf_BOOLEAN) {
        return PLTUBA_CALLBACK_BOOLEAN;
    } else if (state->special_flags & (JSONSL_SPECIALf_NUMERIC | JSONSL_SPECIALf_DASH)) {
        return PLTUBA_CALLBACK_NUMBER;
    } else if (state->special_flags == JSONSL_SPECIALf_NULL) {
        return PLTUBA_CALLBACK_NULL;
    }
    warn("Special flag is %d", state->special_flags);
    die("wtf?");
    return 0;
}

/**
 * This function invokes the selected callback (if it exists).
 */
#define pltuba_invoke_callback(tb,a,cbt,sv) \
    pltuba_invoke_callback_THX(aTHX_ tb,a,cbt,sv)
static void
pltuba_invoke_callback_THX(pTHX_ PLTUBA *tuba,
                           int action,
                           pltuba_callback_type cbtype,
                           SV *mextrasv)
{
    dSP;
    GV **methp = NULL;
    GV *meth = NULL;
    const char *meth_name = NULL;
    int effective_type = cbtype;
    int effective_action = action;
    int stop_mro = 0;
    /**
     * If we are in a pop mode of a callback with the accumulator flag set,
     * then we provide the data in the SV as the argument (maybe with some
     * conversion into an appropriate object), otherwise, we just signal as
     * normal.
     */
    cbtype &= 0x7f;

    if (tuba->accum && action == JSONSL_ACTION_POP) {
        effective_action = PLTUBA_ACTION_ON;
        pltuba_get_method_info(tuba, PLTUBA_ACTION_ON, cbtype, &methp, &meth_name);
        assert(mextrasv == NULL);
        mextrasv = tuba->accum;
        tuba->accum = NULL;
    } else {
        pltuba_get_method_info(tuba, action, cbtype, &methp, &meth_name);
    }

    if (meth_name == NULL) {
        die("Can't find method name. Action=%c, Type=%c", action, cbtype);
    }

    if (!mextrasv) {
        mextrasv = &PL_sv_undef;
    } else {
        sv_2mortal(mextrasv);
    }

    assert(methp);

    if (tuba->last_stash != SvSTASH(SvRV(tuba->selfrv))) {
        pltuba_invalidate_gvs_THX(aTHX_ tuba);
        tuba->last_stash = SvSTASH(SvRV(tuba->selfrv));
    }

    do {
        if (*methp == NULL) {
            meth = gv_fetchmethod_autoload(SvSTASH(SvRV(tuba->selfrv)), meth_name, 1);
            if (meth && GvCV(meth)) {
                if (tuba->options.no_cache_mro == 0) {
                    *methp = meth;
                    SvREFCNT_inc(meth);
                }
                break;
            } /* else */
            pltuba_get_method_info(tuba, PLTUBA_ACTION_ON,
                                   PLTUBA_CALLBACK_ANY, &methp, &meth_name);
            assert(methp && meth_name);
            stop_mro++;
        } else {
            meth = *methp;
            break;
        }
    } while (stop_mro < 2);

    PLTUBA_SET_PARAMFIELDS_dv(tuba, Mode, effective_action);
    PLTUBA_SET_PARAMFIELDS_dv(tuba, Type, effective_type);

    /**
     * We still want a SAVETMPS/FREETMPS pair active before we decide
     * to call a function or not, as the contents mextrasv and possibly
     * some of the hash values are mortalized.
     */
    ENTER; SAVETMPS;
    if (meth && GvCV(meth)) {
        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(tuba->selfrv);
        PUSHs(tuba->paramhvrv);
        if (mextrasv != &PL_sv_undef) {
            XPUSHs(mextrasv);
        }
        PUTBACK;
        call_sv((SV*)GvCV(meth), G_DISCARD);
    } else {
        if (!tuba->options.allow_unhandled) {
            die("Tuba: Cannot find handler for mode 0x%02x action 0x%02x",
                effective_action, effective_type);
        }
    }
    FREETMPS; LEAVE;
}

/**
 * Flush characters between the invocation of the last callback
 * and the current one. the until argument is the end position (inclusive)
 * at which we should stop submitting 'character' data.
 */
#define pltuba_flush_characters(tb,end) \
    pltuba_flush_characters_THX(aTHX_ tb,end)
static void
pltuba_flush_characters_THX(pTHX_ PLTUBA *tuba, size_t until)
{
    STRLEN toFlush;
    const char *buf;
    SV *chunksv;

    if (!tuba->keep_pos) {
        return;
    }

    toFlush = (until - tuba->keep_pos);
    if (toFlush == 0) {
        return;
    }
    buf = GET_STATE_BUFFER(tuba, tuba->keep_pos);

    if (tuba->shift_quote) {
        buf++;
        toFlush--;
    }

    tuba->keep_pos = 0;
    tuba->shift_quote = 0;

    if (toFlush == 0 && tuba->shift_quote == 0) {
        /* if we have no data and the count was not artificially decremented, then
         * don't invoke the callback
         */
        return;
    }

    /* if accumulator mode is on, don't send the data right away.
     * buffer it instead */
    if (tuba->accum) {
        sv_catpvn(tuba->accum, buf, toFlush);
        return;
    } /* else, no accum for this state */

    chunksv = newSVpvn(buf, toFlush);
    pltuba_invoke_callback(tuba,
                           PLTUBA_ACTION_ON,
                           PLTUBA_CALLBACK_DATA,
                           chunksv);
    /**
     * SV has been mortalized by the invoke_callback function
     */
}
/**
 * Push callback. This is easy because we never actually do any character
 * data here.
 */
static void
pltuba_jsonsl_push_callback(jsonsl_t jsn,
                            jsonsl_action_t action,
                            struct jsonsl_state_st *state,
                            const char *at)
{
    PLTUBA *tuba = (PLTUBA*)jsn->data;
    PLJSONSL_dTHX(tuba);
    struct jsonsl_state_st *parent = jsonsl_last_state(jsn, state);
    pltuba_callback_type cbt = convert_to_tuba_cbt(state);
    if (state->level == 1) {
        pltuba_invoke_callback(tuba, action, PLTUBA_CALLBACK_JSON, NULL);
    } else {
        assert(parent);
        if (parent->type == JSONSL_T_LIST) {
            PLTUBA_SET_PARAMFIELDS_iv(tuba, Index, parent->nelem-1);
        } else {
            PLTUBA_RESET_PARAMFIELD(tuba, Index);
        }
    }

    if (tuba->accum_options[cbt & 0x7f]) {
        assert(tuba->accum == NULL);
        /* accum is only ever valid for atomic types */
        tuba->accum = newSVpvn("", 0);
    } else {
        if (JSONSL_STATE_IS_CONTAINER(state) && tuba->kaccum) {
            sv_2mortal(tuba->kaccum);
            tuba->kaccum = NULL;
            pltuba_invoke_callback(tuba, action, cbt, NULL);
            PLTUBA_RESET_PARAMFIELD(tuba, Key);
        } else {
            pltuba_invoke_callback(tuba, action, cbt, NULL);
        }
    }

    /* This is a different branch and must get executed regardless
     * of whether we invoke a callback or use the accumulator */
    if (!JSONSL_STATE_IS_CONTAINER(state)) {
        tuba->keep_pos = state->pos_begin;
        if (state->type & JSONSL_Tf_STRINGY) {
            tuba->shift_quote = 1;
        }
    } else {
        tuba->keep_pos = 0;
    }
}

/**
 * If we're special, then convert all weird stuff to their
 * proper perly form. Simple plain integers are not weird and
 * can be stringified on demand.
 * This is akin to JSON::SL's process_string and process_special
 * functions.
 */
#define pltuba_process_accum(tuba, state) \
    pltuba_process_accum_THX(aTHX_ tuba, state)
static void
pltuba_process_accum_THX(pTHX_
                         PLTUBA *tuba,
                         struct jsonsl_state_st *state)
{
    size_t poscur = tuba->jsn->pos;
    if (state->type == JSONSL_T_SPECIAL) {
        SV *newsv;

        if ( (state->special_flags & JSONSL_SPECIALf_NUMERIC) &&
                (state->special_flags & JSONSL_SPECIALf_NUMNOINT) == 0) {
            goto GT_NONEWSV;

        } else if (state->special_flags & JSONSL_SPECIALf_NUMNOINT) {
            newsv = pljsonsl_common_mknumeric(state,
                                              SvPVX_const(tuba->accum),
                                              poscur - state->pos_begin);
        } else if (state->special_flags & JSONSL_SPECIALf_BOOLEAN) {
            newsv = pljsonsl_common_mkboolean((PLJSONSL*)tuba,
                                              state->special_flags);
        } else {
            newsv = &PL_sv_undef;
        }
        SvREFCNT_dec(tuba->accum);
        tuba->accum = newsv;
        GT_NONEWSV:
        ;
    } else {
        if (tuba->options.utf8) {
            SvUTF8_on(tuba->accum);
        }
        if (state->nescapes) {
            jsonsl_error_t err;
            jsonsl_special_t flags;
            size_t newlen;
            newlen = jsonsl_util_unescape_ex(SvPVX_const(tuba->accum),
                                             SvPVX(tuba->accum),
                                             SvCUR(tuba->accum),
                                             tuba->escape_table,
                                             &flags,
                                             &err,
                                             NULL);
            if (newlen == 0) {
                die("Could not unescape string: %s", jsonsl_strerror(err));
            }
            SvCUR_set(tuba->accum, newlen);
            if (flags & JSONSL_SPECIALf_NONASCII) {
                SvUTF8_on(tuba->accum);
            }
        }
    }
}

static void
pltuba_jsonsl_pop_callback(jsonsl_t jsn,
                           jsonsl_action_t action,
                           struct jsonsl_state_st *state,
                           const char *at)
{
    PLTUBA *tuba = (PLTUBA*)jsn->data;
    PLJSONSL_dTHX(tuba);
    pltuba_callback_type cbt = convert_to_tuba_cbt(state);
    size_t poscur = jsn->pos;

    if (!JSONSL_STATE_IS_CONTAINER(state)) {
        /* Special handling for character crap.. */
        pltuba_flush_characters(tuba, poscur);


        if (tuba->accum) {
            pltuba_process_accum(tuba, state);
        } else {
            if (state->nescapes) {
                PLTUBA_SET_PARAMFIELDS_sv(tuba, Escaped, &PL_sv_yes);
            }
        }

        if (state->type == JSONSL_T_HKEY &&
                tuba->options.accum_kv) {
            /**
             * If we are accumulating the key then don't flush characters under
             * any circumstances. Just swap over the accumulator buffer
             */
            assert(tuba->accum);
            tuba->kaccum = tuba->accum;
            tuba->accum = NULL;
            tuba->keep_pos = 0;
            PLTUBA_SET_PARAMFIELDS_sv(tuba, Key, tuba->kaccum);
            return;
        }
    }

    if (tuba->kaccum && state->type != JSONSL_T_HKEY) {
        sv_2mortal(tuba->kaccum);
        tuba->kaccum = NULL;
    }

    pltuba_invoke_callback(tuba, action, cbt, NULL);

    /**
     * Clear all fields
     */
#define X(kname) \
    PLTUBA_RESET_PARAMFIELD(tuba, kname);
    PLTUBA_XPARAMS;
#undef X

    if (state->level == 1) {
        pltuba_invoke_callback(tuba, action, PLTUBA_CALLBACK_JSON, NULL);
    }
    tuba->keep_pos = 0;
}

static int
pltuba_jsonsl_error_callback(jsonsl_t jsn,
                             jsonsl_error_t error,
                             struct jsonsl_state_st *state,
                             char *at)
{
    /**
     * This needs special handling, as we will be receiving a return
     * value from Perl for this..
     */
    die ("Got error: %s", jsonsl_strerror(error));
    return 0;
}

#define pltuba_feed(tb,str) pltuba_feed_THX(aTHX_ tb,str)
static void
pltuba_feed_THX(pTHX_ PLTUBA *tuba, SV *input)
{
    if (!SvPOK(input)) {
        die("Input is not string!");
    }
    tuba->buf = input;
    tuba->pos_min_valid = tuba->jsn->pos;

    SvREADONLY_on(input);
    jsonsl_feed(tuba->jsn, SvPVX_const(input), SvCUR(input));
    if (tuba->keep_pos) {
        pltuba_flush_characters(tuba, tuba->jsn->pos);
        tuba->keep_pos = tuba->jsn->pos;
    }
    SvREADONLY_off(input);
}

static SV *
pltuba_initialize_THX(pTHX_ const char *pkg)
{
    SV *ptriv, *retrv;
    HV *hvret;
    HV *subclass;
    dMY_CXT;

    /* Initialize our internal C data structures */
    PLTUBA *tuba;
    Newxz(tuba, 1, PLTUBA);
    pljsonsl_common_initialize(&MY_CXT, (PLJSONSL*)tuba, PLJSONSL_MAX_DEFAULT);

    tuba->jsn->action_callback_PUSH = pltuba_jsonsl_push_callback;
    tuba->jsn->action_callback_POP = pltuba_jsonsl_pop_callback;
    tuba->jsn->error_callback = pltuba_jsonsl_error_callback;
    jsonsl_enable_all_callbacks(tuba->jsn);

    ptriv = newSViv(PTR2IV(tuba));
    SvREADONLY_on(ptriv);

    /* The Perl object .. */
    hvret = newHV();
    (void)hv_stores(hvret, PLTUBA_HKEY_NAME, ptriv);
    tuba->selfrv = newRV_inc((SV*)hvret);
    sv_rvweaken(tuba->selfrv);
    retrv = newRV_noinc((SV*)hvret);

    subclass = gv_stashpv(pkg, GV_ADD);
    sv_bless(retrv, subclass);

    tuba->paramhv = newHV();
    tuba->paramhvrv = newRV_noinc((SV*)tuba->paramhv);
    {
        SV *ksv = newSV(0);
        HE *tmphe;

#define X(kname) \
        sv_setpvs(ksv, #kname); \
        tmphe = hv_store_ent(tuba->paramhv, ksv, &PL_sv_undef, 0); \
        HeVAL(tmphe) = &PL_sv_placeholder; \
        assert(tmphe); \
        tuba->p_ents.pe_##kname.he = tmphe;

        PLTUBA_XPARAMS;
#undef X
    }

#define initialize_param_iv(b) \
    PLTUBA_PARAM_FIELD(tuba, b).sv = newSViv(0); \
    SvREADONLY_on(PLTUBA_PARAM_FIELD(tuba,b).sv);
#define initialize_param_dualvar(b) \
    PLTUBA_PARAM_FIELD(tuba, b).sv = newSViv(0); \
    sv_setpv(PLTUBA_PARAM_FIELD(tuba, b).sv, " "); \
    SvIOK_on(PLTUBA_PARAM_FIELD(tuba,b).sv); \
    SvREADONLY_on(PLTUBA_PARAM_FIELD(tuba,b).sv);

    initialize_param_iv(Index);
    initialize_param_dualvar(Mode);
    initialize_param_dualvar(Type);

#undef initialize_param_iv
#undef initialize_param_dualvar

    SvREADONLY_on(tuba->paramhv);
    return retrv;
}

/**
 * Initialize our thread-local context
 */
#define POPULATE_CXT \
    MY_CXT.stash_obj = gv_stashpv(PLJSONSL_CLASS_NAME, GV_ADD); \
    MY_CXT.stash_boolean = gv_stashpv(PLJSONSL_BOOLEAN_NAME, GV_ADD); \
    MY_CXT.stash_tuba = gv_stashpv(PLTUBA_CLASS_NAME, GV_ADD); \
    MY_CXT.quick = NULL;


/**
 * These two macros arrange for the contents of the result stack to be returned
 * to perlspace.
 */
#define dRESULT_VARS \
    int result_count; \
    int result_iter; \
    SV *result_sv;

#define RETURN_RESULTS(pjsn) \
    switch(GIMME_V) { \
    case G_VOID: \
        result_count = 0; \
        break; \
    case G_SCALAR: \
        result_sv = av_shift(pjsn->results); \
        if (result_sv == &PL_sv_undef) { \
            result_count = 0; \
            break; \
        } \
        XPUSHs(sv_2mortal(result_sv)); \
        result_count = 1; \
        break; \
    case G_ARRAY: \
        result_count = av_len(pjsn->results) + 1; \
        if (result_count == 0) { \
            break; \
        } \
        EXTEND(SP, result_count); \
        for (result_iter = 0; result_iter < result_count; result_iter++) { \
            result_sv = av_delete(pjsn->results, result_iter, 0); \
            /*already mortal according to av_delete*/ \
            PUSHs(result_sv); \
        } \
        av_clear(pjsn->results); \
        break; \
    default: \
        die("eh? (RETURN_RESULTS)"); \
        result_count = 0; \
        break; \
    }




MODULE = JSON::SL PACKAGE = JSON::SL PREFIX = PLJSONSL_

PROTOTYPES: DISABLED

BOOT:
{
    MY_CXT_INIT;
    POPULATE_CXT;
    PLJSONSL_ESCTBL_INIT(ESCTBL);
}

SV *
PLJSONSL_new(SV *pkg, ...)
    PREINIT:
    PLJSONSL *pjsn;
    SV *ptriv, *retrv;
    int levels;
    dMY_CXT;
    CODE:
    (void)pkg;
    if (items > 1) {
        if (!SvIOK(ST(1))) {
            die("Second argument (if provided) must be numeric");
        }
        levels = SvIV(ST(1));
        if (levels < 2) {
            die ("Levels must be at least 2");
        }
    } else {
        levels = PLJSONSL_MAX_DEFAULT;
    }

    Newxz(pjsn, 1, PLJSONSL);
    pljsonsl_common_initialize(&MY_CXT, pjsn, levels);
    ptriv = newSViv(PTR2IV(pjsn));
    retrv = newRV_noinc(ptriv);
    sv_bless(retrv, MY_CXT.stash_obj);
    pjsn->buf = newSVpvn("", 0);

    jsonsl_enable_all_callbacks(pjsn->jsn);
    pjsn->jsn->action_callback = initial_callback;
    pjsn->jsn->error_callback = error_callback;

    pjsn->results = newAV();
    PLJSONSL_INIT_KSV(pjsn);
    RETVAL = retrv;

    OUTPUT: RETVAL


void
PLJSONSL_set_jsonpointer(PLJSONSL *pjsn, AV *paths)
    PPCODE:
    pljsonsl_set_jsonpointer(pjsn, paths);

SV *
PLJSONSL_root(PLJSONSL *pjsn)
    CODE:
    if (pjsn->root) {
        RETVAL = newRV_inc(pjsn->root);
    } else {
        RETVAL = &PL_sv_undef;
    }
    OUTPUT: RETVAL

void
PLJSONSL__modify_readonly(PLJSONSL *pjsn, SV *ref)
    ALIAS:
    make_referrent_writeable = 1
    make_referrent_readonly = 2
    CODE:
    if (!SvROK(ref)) {
        die("Variable is not a reference!");
    }
    if (ix == 0) {
        PLJSONSL_CROAK_USAGE("use make_referrent_writeable or make_referrent_readonly");
    } else if (ix == 1) {
        SvREADONLY_off(SvRV(ref));
    } else if (ix == 2) {
        SvREADONLY_on(SvRV(ref));
    }

int
PLJSONSL_referrent_is_writeable(PLJSONSL *pjsn, SV *ref)
    CODE:
    if (!SvROK(ref)) {
        die("Variable is not a reference!");
    }
    RETVAL = SvREADONLY(SvRV(ref)) == 0;
    OUTPUT: RETVAL


void
PLJSONSL_feed(PLJSONSL *pjsn, SV *input)
    ALIAS:
    incr_parse =1

    PPCODE:
    {
    dRESULT_VARS;
    pljsonsl_feed_incr(pjsn, input);
    RETURN_RESULTS(pjsn);
    }

void
PLJSONSL_fetch(PLJSONSL *pjsn)
    PPCODE:
    {
    dRESULT_VARS;
    RETURN_RESULTS(pjsn);
    }

int
PLJSONSL__escape_table_chr(PLJSONSL *pjsn, U8 chrc, ...)
    CODE:
    if (chrc > 0x7f) {
        warn("Attempted to set non-ASCII escape preference");
        RETVAL = -1;
    } else {
        RETVAL = pjsn->escape_table[chrc];
        if (items == 3) {
            pjsn->escape_table[chrc] = SvIV(ST(2));
        }
    }
    OUTPUT: RETVAL

void
PLJSONSL_reset(PLJSONSL *pjsn)
    CODE:
    REFDEC_FIELD(pjsn, root);

    if (pjsn->results) {
        av_clear(pjsn->results);
    }
    if (pjsn->buf) {
        SvCUR_set(pjsn->buf, 0);
    }

    jsonsl_reset(pjsn->jsn);
    pjsn->pos_min_valid = 0;
    pjsn->keep_pos = 0;
    pjsn->curhk = NULL;
    pjsn->jsn->action_callback_PUSH = initial_callback;

SV*
PLJSONSL_root_callback(PLJSONSL *pjsn, SV *callback)
    CODE:
    RETVAL = pjsn->options.root_callback;
    if (RETVAL) {
        SvREFCNT_inc(RETVAL);
    } else {
        RETVAL = &PL_sv_undef;
    }

    if (SvTYPE(callback) == SVt_NULL) {
        if (pjsn->options.root_callback) {
            SvREFCNT_dec(pjsn->options.root_callback);
            pjsn->options.root_callback = NULL;
        }
    } else {
        if (SvTYPE(callback) != SVt_RV ||
                SvTYPE(SvRV(callback)) != SVt_PVCV) {
            die("Second argument must be undef or a CODE ref");
        }
        if (pjsn->options.root_callback) {
            SvREFCNT_dec(pjsn->options.root_callback);
        }
        pjsn->options.root_callback = newRV_inc(SvRV(callback));
    }

    OUTPUT: RETVAL

void
PLJSONSL_DESTROY(PLJSONSL *pjsn)
    PREINIT:
    int ii;

    CODE:
    if (pjsn->priv_global.is_global == 0) {
        REFDEC_FIELD(pjsn, root);
        REFDEC_FIELD(pjsn, results);
        REFDEC_FIELD(pjsn, buf);
        REFDEC_FIELD(pjsn, options.root_callback);
    } /* else, it's a mortal and shouldn't be freed */
    jsonsl_jpr_match_state_cleanup(pjsn->jsn);
    if (pjsn->jprs) {
        for ( ii = 0; ii < pjsn->njprs; ii++) {
            if (pjsn->jprs[ii] == NULL) {
                break;
            }
            jsonsl_jpr_destroy(pjsn->jprs[ii]);
        }
        Safefree(pjsn->jprs);
        pjsn->jprs = NULL;
    }
    if (pjsn->jsn) {
        jsonsl_destroy(pjsn->jsn);
        pjsn->jsn = NULL;
    }
    PLJSONSL_DESTROY_KSV(pjsn);
    Safefree(pjsn);

void
PLJSONSL_decode_json(SV *input)
    PREINIT:
    PLJSONSL* pjsn;
    dRESULT_VARS;

    PPCODE:
    pjsn = pljsonsl_get_and_initialize_global(aTHX);
    pljsonsl_feed_oneshot(pjsn, input);

    pjsn->curhk = NULL;
    pjsn->keep_pos = 0;
    pjsn->pos_min_valid = 0;
    pjsn->jsn->action_callback_PUSH = initial_callback;

    RETURN_RESULTS(pjsn);
    if (result_count == 0 && av_len(pjsn->results) == -1) {
        die("Incomplete JSON string?");
    }

SV *
PLJSONSL_unescape_json_string(SV *input)
    PREINIT:
    size_t origlen, newlen;
    SV *retsv = NULL;
    char *errpos;
    jsonsl_error_t err;
    jsonsl_special_t flags;

    CODE:
    if (!SvPOK(input)) {
        die("Input is not a valid string");
    }
    origlen = SvCUR(input);
    if (origlen) {
        retsv = newSV(origlen);
        newlen = jsonsl_util_unescape_ex(SvPVX_const(input), SvPVX(retsv),
                                    SvCUR(input), ESCTBL, &flags,
                                    &err, (const char**)&errpos);
        if (newlen == 0) {
            SvREFCNT_dec(retsv);
            die("Could not unescape: %s at pos %lu ('%c'..)",
                jsonsl_strerror(err),
                errpos - SvPVX_const(input),
                *errpos
            );
        }

        SvCUR_set(retsv, newlen);
        SvPOK_only(retsv);
        if (SvUTF8(input) || (flags & JSONSL_SPECIALf_NONASCII)) {
            SvUTF8_on(retsv);
        }
    } else {
        retsv = &PL_sv_undef;
    }
    RETVAL = retsv;
    OUTPUT: RETVAL



void
PLJSONSL_CLONE(PLJSONSL *pjsn)
    CODE:
    {
    MY_CXT_CLONE;
    POPULATE_CXT;
    }

MODULE = JSON::SL PACKAGE = JSON::SL::Tuba PREFIX = PLTUBA_

SV *
PLTUBA__initialize(const char *pkg)
    CODE:
    RETVAL = pltuba_initialize_THX(aTHX_ pkg);
    OUTPUT: RETVAL

void
PLTUBA_DESTROY(PLTUBA* tuba)
    CODE:
    jsonsl_destroy(tuba->jsn);
    tuba->jsn = NULL;

    REFDEC_FIELD(tuba, accum);
    REFDEC_FIELD(tuba, kaccum);
    REFDEC_FIELD(tuba, selfrv);
#define X(kname) \
    PLTUBA_RESET_PARAMFIELD(tuba, kname); \
    REFDEC_FIELD(tuba, p_ents.pe_##kname.sv);
    PLTUBA_XPARAMS;
#undef X
    REFDEC_FIELD(tuba, paramhvrv);
    /* Implicit that the hash has been decrementas as well.
     * Don't do another dec
     */
    tuba->paramhv = NULL;
    pltuba_invalidate_gvs_THX(aTHX_ tuba);
    Safefree(tuba);

int
PLTUBA__ax_opt(PLTUBA *tuba, int mode, ...)
    CODE:
    RETVAL = tuba->accum_options[mode & 0xff];
    if (items > 2) {
        tuba->accum_options[mode & 0xff] = SvIV(ST(2));
    }
    OUTPUT: RETVAL

int
PLTUBA_accum_kv(PLTUBA *tuba, ...)
    CODE:
    if (items > 2) {
        die("accum_kv(..boolean)");
    }
    RETVAL = tuba->options.accum_kv;
    if (items == 2) {
        int newval = SvIV(ST(1));
        if (newval) {
            tuba->accum_options['#'] = 1;
        }
        tuba->options.accum_kv = newval;
    }
    OUTPUT: RETVAL


void
PLTUBA__parse(PLTUBA* tuba, SV *input)
    CODE:
    pltuba_feed(tuba, input);


INCLUDE: srcout/option_accessors.xs
