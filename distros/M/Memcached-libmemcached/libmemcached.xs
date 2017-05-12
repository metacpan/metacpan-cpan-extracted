/*
 * vim: expandtab:sw=4
 * */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libmemcached/memcached.h>

#define MEMCACHED_CALLBACK_MALLOC_FUNCTION 4
#define MEMCACHED_CALLBACK_REALLOC_FUNCTION 5
#define MEMCACHED_CALLBACK_FREE_FUNCTION 6

/* See also the typemap as most of the interesting glue is there */

/* mapping C types to perl classes - keep typemap file in sync */
typedef memcached_st*        Memcached__libmemcached;
typedef uint32_t             lmc_data_flags_t;
typedef char*                lmc_key;
typedef char*                lmc_value;
typedef time_t               lmc_expiration;

/* pointer chasing:
 *
 * $memc is a scalar (SV) containing a reference (RV) to a hash (HV) with magic (mg):
 *
 * RV -> HV -> mg -> lmc_state -> memcached_st (-> MEMCACHED_CALLBACK_USER_DATA points back to lmc_state)
 *
 */

/* get a memcached_st structure from a $memc */
#define LMC_STATE_FROM_SV(sv) \
    (mg_find(SvRV(sv), '~')->mg_obj)

#define LMC_PTR_FROM_SV(sv) \
    ((lmc_state_st*)LMC_STATE_FROM_SV(sv))->ptr

/* get our lmc_state structure from a memcached_st ptr */
#define LMC_STATE_FROM_PTR(ptr) \
    ((lmc_state_st*)memcached_callback_get(ptr, MEMCACHED_CALLBACK_USER_DATA, NULL))

/* get trace level from memcached_st ptr */
#define LMC_TRACE_LEVEL_FROM_PTR(ptr) \
    ((ptr) ? LMC_STATE_FROM_PTR(ptr)->trace_level : 0)

/* check memcached_return value counts as success */
#define LMC_RETURN_OK(ret) \
    (ret==MEMCACHED_SUCCESS || ret==MEMCACHED_STORED || ret==MEMCACHED_DELETED || ret==MEMCACHED_END || ret==MEMCACHED_BUFFERED)

/* store memcached_return value in our lmc_state structure */
#define LMC_RECORD_RETURN_ERR(what, ptr, ret) \
    STMT_START {    \
        lmc_state_st* lmc_state = LMC_STATE_FROM_PTR(ptr); \
        if (lmc_state) { \
            if (lmc_state->trace_level > 1 || (lmc_state->trace_level && !LMC_RETURN_OK(ret))) \
                warn("\t<= %s return %d %s", what, ret, memcached_strerror(ptr, ret)); \
            lmc_state->last_return = ret;   \
            lmc_state->last_errno  = memcached_last_error_errno(ptr); /* if MEMCACHED_ERRNO */ \
        } else { /* should never happen */ \
            warn("LMC_RECORD_RETURN_ERR(%d %s): no lmc_state structure in memcached_st so error not recorded!", \
                ret, memcached_strerror(ptr, ret)); \
        } \
    } STMT_END


/* ====================================================================================== */


typedef struct lmc_state_st lmc_state_st;
typedef struct lmc_cb_context_st lmc_cb_context_st;

/* context information for callbacks */
struct lmc_cb_context_st {
    lmc_state_st *lmc_state;
    SV *dest_sv;
    HV *dest_hv;
    memcached_return *rc_ptr;
    lmc_data_flags_t *flags_ptr;
    UV  result_count;
    SV  *get_cb;
    SV  *set_cb;
    /* current set of keys for mget */
    char   **key_strings;
    size_t  *key_lengths;
    IV       key_alloc_count;
};

/* perl api state information associated with an individual memcached_st */
struct lmc_state_st {
    memcached_st    *ptr;
    HV              *hv;    /* pointer back to HV (not refcntd) */
    IV               trace_level;
    int              options;
    memcached_return last_return;
    int              last_errno;
    /* handy default fetch context for fetching single items */
    lmc_cb_context_st *cb_context; /* points to _cb_context by default */
    lmc_cb_context_st _cb_context;
};

static lmc_state_st *
lmc_state_new(memcached_st *ptr, HV *memc_hv)
{
    char *trace = getenv("PERL_LIBMEMCACHED_TRACE");
    lmc_state_st *lmc_state;
    Newz(0, lmc_state, 1, struct lmc_state_st);
    lmc_state->ptr = ptr;
    lmc_state->hv  = memc_hv;
    lmc_state->cb_context = &lmc_state->_cb_context;
    lmc_state->cb_context->lmc_state = lmc_state;
    lmc_state->cb_context->set_cb = newSV(0);
    lmc_state->cb_context->get_cb = newSV(0);
    if (trace) {
        lmc_state->trace_level = (IV)atoi(trace);
    }
    return lmc_state;
}


/* ====================================================================================== */


static void
_prep_keys_buffer(lmc_cb_context_st *lmc_cb_context, int keys_needed)
{
    IV trace_level = lmc_cb_context->lmc_state->trace_level;
    if (keys_needed <= lmc_cb_context->key_alloc_count) {
        if (trace_level >= 9)
            warn("reusing keys buffer");
        return;
    }
    if (!lmc_cb_context->key_strings) {
        Newx(lmc_cb_context->key_strings, keys_needed, char *);
        Newx(lmc_cb_context->key_lengths, keys_needed, size_t);
        if (trace_level >= 3)
            warn("new keys buffer");
    }
    else {
        keys_needed *= 1.2;
        Renew(lmc_cb_context->key_strings, keys_needed, char *);
        Renew(lmc_cb_context->key_lengths, keys_needed, size_t);
        if (trace_level >= 3)
            warn("growing keys buffer %d->%d", (int)lmc_cb_context->key_alloc_count, keys_needed);
    }
    lmc_cb_context->key_alloc_count = keys_needed;
}


static memcached_return
_prep_keys_lengths(memcached_st *ptr, SV *keys_rv, char ***out_keys, size_t **out_key_length, unsigned int *out_number_of_keys)
{
    SV *keys_sv;
    unsigned int number_of_keys;
    char **keys;
    size_t *key_length;
    int i = 0;

    lmc_state_st *lmc_state = LMC_STATE_FROM_PTR(ptr);
    lmc_cb_context_st *lmc_cb_context = lmc_state->cb_context;

    if (!SvROK(keys_rv))
        return MEMCACHED_NO_KEY_PROVIDED;
    keys_sv = SvRV(keys_rv);
    if (SvRMAGICAL(keys_rv)) /* disallow tied arrays for now */
        return MEMCACHED_NO_KEY_PROVIDED;

    if (SvTYPE(keys_sv) == SVt_PVAV) {
        number_of_keys = AvFILL(keys_sv)+1;
        if (number_of_keys > lmc_cb_context->key_alloc_count)
            _prep_keys_buffer(lmc_cb_context, number_of_keys);
        keys       = lmc_cb_context->key_strings;
        key_length = lmc_cb_context->key_lengths;
        for (i = 0; i < number_of_keys; i++) {
            keys[i] = SvPV(AvARRAY(keys_sv)[i], key_length[i]);
        }
    }
    else if (SvTYPE(keys_sv) == SVt_PVHV) {
        HE *he;
        I32 retlen;
        hv_iterinit((HV*)keys_sv);
        number_of_keys = HvKEYS(keys_sv);
        if (number_of_keys > lmc_cb_context->key_alloc_count)
            _prep_keys_buffer(lmc_cb_context, number_of_keys);
        keys       = lmc_cb_context->key_strings;
        key_length = lmc_cb_context->key_lengths;
        while ( (he = hv_iternext((HV*)keys_sv)) ) {
            keys[i] = hv_iterkey(he, &retlen);
            key_length[i++] = retlen;
        }
    }
    else {
        return MEMCACHED_NO_KEY_PROVIDED;
    }
    *out_number_of_keys = number_of_keys;
    *out_keys           = keys;
    *out_key_length     = key_length;
    return MEMCACHED_SUCCESS;
}


/* ====================================================================================== */

/* --- callbacks for memcached_fetch_execute ---
 */

static unsigned int
_cb_prep_store_into_sv_of_hv(memcached_st *ptr, memcached_result_st *result, void *context)
{
    /* Set dest_sv to the appropriate sv in dest_hv              */
    /* Called before _cb_store_into_sv when fetching into a hash */
    lmc_cb_context_st *lmc_cb_context = context;
    SV **svp = hv_fetch( lmc_cb_context->dest_hv, memcached_result_key_value(result), memcached_result_key_length(result), 1);
    lmc_cb_context->dest_sv = *svp;
    return 0;
}

static unsigned int
_cb_store_into_sv(memcached_st *ptr, memcached_result_st *result, void *context)
{
    /* Store result value and flags into places specified by lmc_cb_context */
    /* This is the 'core' fetch callback. Increments result_count.             */
    lmc_cb_context_st *lmc_cb_context = context;
    ++lmc_cb_context->result_count;
    *lmc_cb_context->flags_ptr = memcached_result_flags(result);
    sv_setpvn(lmc_cb_context->dest_sv, memcached_result_value(result), memcached_result_length(result));
    if (lmc_cb_context->lmc_state->trace_level >= 2)
        warn("fetched %s (value len %d, flags %lu)\n",
            memcached_result_key_value(result), (int) memcached_result_length(result), (long unsigned int)memcached_result_flags(result));
    return 0;
}


/* XXX - Notes:
 * Perl callbacks are called as
 *
 *    sub {
 *      my ($key, $flags) = @_;  # with $_ containing the value
 *    }
 *
 * Modifications to $_ (value) and $_[1] (flags) propagate to other callbacks,
 * and thus to libmemcached.
 * Callbacks can't recurse within the same $memc at the moment.
 */
static unsigned int
_cb_fire_perl_cb(lmc_cb_context_st *lmc_cb_context, SV *callback_sv, SV *key_sv, SV *value_sv, SV *flags_sv, SV *cas_sv)
{
    int items;
    dSP;

    ENTER;
    SAVETMPS;

    SAVE_DEFSV; /* local($_) = $value */
    DEFSV = value_sv;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(key_sv);
    PUSHs(flags_sv);
    if (cas_sv)
        PUSHs(cas_sv);
    PUTBACK;

    items = call_sv(callback_sv, G_ARRAY);
    SPAGAIN;

    if (items) /* may use returned items for signalling later */
        croak("callback returned non-empty list");

    FREETMPS;
    LEAVE;
    return 0;
}


static unsigned int
_cb_fire_perl_set_cb(memcached_st *ptr, SV *key_sv, SV *value_sv, SV *flags_sv)
{
    /* XXX note different api to _cb_fire_perl_get_cb */
    lmc_state_st *lmc_state = LMC_STATE_FROM_PTR(ptr);
    lmc_cb_context_st *lmc_cb_context = lmc_state->cb_context;
    unsigned int status;

    if (!SvOK(lmc_cb_context->set_cb))
        return 0;

    status = _cb_fire_perl_cb(lmc_cb_context, lmc_cb_context->set_cb, key_sv, value_sv, flags_sv, NULL);
    return status;
}

static unsigned int
_cb_fire_perl_get_cb(memcached_st *ptr, memcached_result_st *result, void *context)
{
    /* designed to be called via memcached_fetch_execute() */
    lmc_cb_context_st *lmc_cb_context = context;
    SV *key_sv, *value_sv, *flags_sv, *cas_sv;
    unsigned int status;

    if (!SvOK(lmc_cb_context->get_cb))
        return 0;

    /* these SVs may get cached inside lmc_cb_context_st and reused across calls */
    /* which would save the create,mortalize,destroy costs for each invocation  */
    key_sv   = sv_2mortal(newSVpv(memcached_result_key_value(result), memcached_result_key_length(result)));
    value_sv = lmc_cb_context->dest_sv;
    flags_sv = sv_2mortal(newSVuv(*lmc_cb_context->flags_ptr));
    if (memcached_behavior_get(ptr, MEMCACHED_BEHAVIOR_SUPPORT_CAS)) {
        uint64_t cas = memcached_result_cas(result);
        warn("cas not fully supported"); /* if sizeof UV < sizeof uint64_t */
        cas_sv = sv_2mortal(newSVuv(cas));
    }
    else cas_sv = NULL;

    SvREADONLY_on(key_sv); /* just to be sure for now, may allow later */

    status = _cb_fire_perl_cb(lmc_cb_context, lmc_cb_context->get_cb, key_sv, value_sv, flags_sv, cas_sv);
    /* recover potentially modified values */
    *lmc_cb_context->flags_ptr = SvUV(flags_sv);

    return status;
}

typedef unsigned int (*memcached_callback_fp)(memcached_st *ptr, memcached_result_st *result, void *context);

memcached_callback_fp lmc_store_hv_get[3][3] = {
    { _cb_prep_store_into_sv_of_hv, _cb_store_into_sv,                       },
    { _cb_prep_store_into_sv_of_hv, _cb_store_into_sv, _cb_fire_perl_get_cb, },
};
memcached_callback_fp lmc_store_sv_get[3][3] = {
    {                               _cb_store_into_sv,                       },
    {                               _cb_store_into_sv, _cb_fire_perl_get_cb, },
};


/* ====================================================================================== */


static SV *
_fetch_one_sv(memcached_st *ptr, lmc_data_flags_t *flags_ptr, memcached_return *error_ptr)
{
    lmc_cb_context_st *lmc_cb_context = LMC_STATE_FROM_PTR(ptr)->cb_context;

    int callback_ix = 0;
    memcached_callback_fp callbacks[5];
    callbacks[callback_ix++] = _cb_store_into_sv;
    if (SvOK(lmc_cb_context->get_cb))
        callbacks[callback_ix++] = _cb_fire_perl_get_cb;
    callbacks[callback_ix  ] = NULL;

    if (*error_ptr != MEMCACHED_SUCCESS)    /* did preceeding mget succeed */
        return &PL_sv_undef;

    lmc_cb_context->dest_sv   = newSV(0);
    lmc_cb_context->flags_ptr = flags_ptr;
    lmc_cb_context->rc_ptr    = error_ptr;
    lmc_cb_context->result_count = 0;

    *error_ptr = memcached_fetch_execute(ptr, (memcached_execute_fn *)callbacks, lmc_cb_context, callback_ix);

    if (lmc_cb_context->result_count == 0 && (*error_ptr == MEMCACHED_SUCCESS || *error_ptr == MEMCACHED_END))
        *error_ptr = MEMCACHED_NOTFOUND; /* to match memcached_get behaviour */
    else if (lmc_cb_context->result_count > 0 && *error_ptr == MEMCACHED_END)
        *error_ptr = MEMCACHED_SUCCESS; /* to match memcached_get behaviour */

    return lmc_cb_context->dest_sv;
}


static memcached_return
_fetch_all_into_hashref(memcached_st *ptr, memcached_return rc, HV *dest_ref)
{
    lmc_cb_context_st *lmc_cb_context = LMC_STATE_FROM_PTR(ptr)->cb_context;
    lmc_data_flags_t flags;

    int callback_ix = 0;
    memcached_callback_fp callbacks[5];
    callbacks[callback_ix++] = _cb_prep_store_into_sv_of_hv;
    callbacks[callback_ix++] = _cb_store_into_sv;
    if (SvOK(lmc_cb_context->get_cb))
        callbacks[callback_ix++] = _cb_fire_perl_get_cb;
    callbacks[callback_ix  ] = NULL;

    lmc_cb_context->dest_hv   = dest_ref;
    lmc_cb_context->flags_ptr = &flags;  /* local, not safe for caller */
    lmc_cb_context->rc_ptr    = &rc;     /* local, not safe for caller */
    lmc_cb_context->result_count = 0;

    /* rc is the return code from the preceeding mget */
    if (!LMC_RETURN_OK(rc)) {
        if (rc == MEMCACHED_INVALID_ARGUMENTS) {
            /* when number_of_keys==0 memcached_mget returns MEMCACHED_INVALID_ARGUMENTS
            * which we'd normally translate into a false return value
            * but that's not really appropriate here
            */
            return MEMCACHED_SUCCESS;
        }
        return rc;
    }

    rc = memcached_fetch_execute(ptr, (memcached_execute_fn *)callbacks, (void *)lmc_cb_context, callback_ix);
    if (rc == MEMCACHED_NOTFOUND || rc == MEMCACHED_SUCCESS) {
        return MEMCACHED_SUCCESS; /* This is a success, no matter what */
    }
    return rc;
}


static memcached_return_t
_walk_stats_cb(const memcached_instance_st *instance,
    const char *key,   size_t key_length,
    const char *value, size_t value_length,
    void *cb)
{
    dSP;
    int items;

    /* callback is called with key, value, hostname, typename */
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(key, key_length)));
    XPUSHs(sv_2mortal(newSVpv(value, value_length)));
    XPUSHs(sv_2mortal(newSVpvf("%s:%d",
        memcached_server_name(instance), memcached_server_port(instance))));
    XPUSHs(DEFSV); /* XXX deprecated $stats_arg in $_ */
    PUTBACK;
    items = call_sv((SV*)cb, G_ARRAY);
    SPAGAIN;
    if (items) /* XXX may use returned items for signalling later */
        croak("walk_stats callback returned non-empty list");

    return MEMCACHED_SUCCESS;
}



MODULE=Memcached::libmemcached  PACKAGE=Memcached::libmemcached

PROTOTYPES: DISABLED

INCLUDE: const-xs.inc


=head2 Functions For Managing libmemcached Objects

=cut

Memcached__libmemcached
memcached_create(Memcached__libmemcached ptr=NULL)
    ALIAS:
        new = 1
    PREINIT:
        SV *class_sv = (items >= 1) ? ST(0) : NULL;
    INIT:
        ptr = NULL; /* force null even if arg provided */
        PERL_UNUSED_VAR(ix);


Memcached__libmemcached
memcached_clone(Memcached__libmemcached clone, Memcached__libmemcached source)
    PREINIT:
        SV *class_sv = (items >= 1) ? ST(0) : NULL;
    INIT:
        clone = NULL; /* force null even if arg provided */


unsigned int
memcached_server_count(Memcached__libmemcached ptr)

memcached_return
memcached_server_add(Memcached__libmemcached ptr, char *hostname, unsigned int port=0)

memcached_return
memcached_server_add_with_weight(Memcached__libmemcached ptr, char *hostname, unsigned int port=0, unsigned int weight)

memcached_return
memcached_server_add_unix_socket(Memcached__libmemcached ptr, char *socket)

memcached_return
memcached_server_add_unix_socket_with_weight(Memcached__libmemcached ptr, char *socket, unsigned int weight)

void
memcached_free(Memcached__libmemcached ptr)
    INIT:
        if (!ptr)   /* garbage or already freed this sv */
            XSRETURN_EMPTY;
    POSTCALL:
        LMC_STATE_FROM_PTR(ptr)->ptr = NULL;

void
DESTROY(SV *sv)
    PPCODE:
    lmc_state_st *lmc_state;
    lmc_cb_context_st *lmc_cb_context;

    lmc_state = (lmc_state_st*)LMC_STATE_FROM_SV(sv);
    if (lmc_state->trace_level >= 2) {
        warn("DESTROY sv %p, state %p, ptr %p", SvRV(sv), lmc_state, lmc_state->ptr);
        if (lmc_state->trace_level >= 9)
            sv_dump(sv);
    }
    if (lmc_state->ptr)
        memcached_free(lmc_state->ptr);

    lmc_cb_context = lmc_state->cb_context;
    sv_free(lmc_cb_context->get_cb);
    sv_free(lmc_cb_context->set_cb);
    Safefree(lmc_cb_context->key_strings);
    Safefree(lmc_cb_context->key_lengths);

    sv_unmagic(SvRV(sv), '~'); /* disconnect lmc_state from HV */
    Safefree(lmc_state);

UV
memcached_behavior_get(Memcached__libmemcached ptr, memcached_behavior flag)

memcached_return
memcached_behavior_set(Memcached__libmemcached ptr, memcached_behavior flag, uint64_t data)

memcached_return
memcached_callback_set(Memcached__libmemcached ptr, memcached_callback flag, SV *data)
    CODE:
    /* we only allow setting of known-safe flags */
    switch (flag) {
    case MEMCACHED_CALLBACK_PREFIX_KEY:
        RETVAL = memcached_callback_set(ptr, flag, SvPV_nolen(data));
        break;
    default:
        RETVAL = MEMCACHED_FAILURE;
        break;
    }
    OUTPUT:
        RETVAL

SV *
memcached_callback_get(Memcached__libmemcached ptr, memcached_callback flag, IN_OUT memcached_return ret=NO_INIT)
    PREINIT:
        void *data = NULL;
    CODE:
    RETVAL = &PL_sv_undef;
    /* we only allow setting of known-safe flags */
    switch (flag) {
    case MEMCACHED_CALLBACK_PREFIX_KEY:
        data = memcached_callback_get(ptr, flag, &ret);
        /* libmemcached treats empty prefix as an error */
        /* we treat it more pragmatically */
        RETVAL = newSVpv((data) ? data : "", 0);
        break;
    default:
        ret = MEMCACHED_FAILURE;
        break;
    }
    OUTPUT:
        RETVAL


=head2 Functions for Setting Values in memcached

=cut

memcached_return
memcached_set(Memcached__libmemcached ptr, \
        lmc_key   key,   size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags= 0)

memcached_return
memcached_set_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key   key,      size_t length(key), \
        lmc_value value,    size_t length(value), \
        lmc_expiration expiration=0, lmc_data_flags_t flags=0)

memcached_return
memcached_add (Memcached__libmemcached ptr, \
        lmc_key   key,   size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0)

memcached_return
memcached_add_by_key(Memcached__libmemcached ptr, \
        lmc_key   master_key, size_t length(master_key), \
        lmc_key   key,        size_t length(key), \
        lmc_value value,      size_t length(value), \
        lmc_expiration expiration=0, lmc_data_flags_t flags=0)

memcached_return
memcached_append(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key),\
        lmc_value value, size_t length(value),\
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0)

memcached_return
memcached_append_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration=0, lmc_data_flags_t flags=0)

memcached_return
memcached_prepend(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0)

memcached_return
memcached_prepend_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration=0, lmc_data_flags_t flags=0)

memcached_return
memcached_replace(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0)

memcached_return
memcached_replace_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration=0, lmc_data_flags_t flags=0)

memcached_return
memcached_cas(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0, uint64_t cas)

memcached_return
memcached_cas_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        lmc_value value, size_t length(value), \
        lmc_expiration expiration= 0, lmc_data_flags_t flags=0, uint64_t cas)


=head2 Functions for Incrementing and Decrementing Values from memcached

=cut

memcached_return
memcached_increment(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        unsigned int offset, IN_OUT uint64_t value=NO_INIT)

memcached_return
memcached_decrement(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        unsigned int offset, IN_OUT uint64_t value=NO_INIT)

memcached_return
memcached_increment_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        unsigned int offset, IN_OUT uint64_t value=NO_INIT)

memcached_return
memcached_decrement_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        unsigned int offset, IN_OUT uint64_t value=NO_INIT)

memcached_return
memcached_increment_with_initial (Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        unsigned int offset, \
        uint64_t initial, \
        lmc_expiration expiration= 0, \
        IN_OUT uint64_t value=NO_INIT)

memcached_return
memcached_decrement_with_initial (Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        unsigned int offset, \
        uint64_t initial, \
        lmc_expiration expiration= 0, \
        IN_OUT uint64_t value=NO_INIT)

memcached_return
memcached_increment_with_initial_by_key (Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        unsigned int offset, \
        uint64_t initial, \
        lmc_expiration expiration= 0, \
        IN_OUT uint64_t value=NO_INIT)

memcached_return
memcached_decrement_with_initial_by_key (Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        unsigned int offset, \
        uint64_t initial, \
        lmc_expiration expiration= 0, \
        IN_OUT uint64_t value=NO_INIT)


=head2 Functions for Fetching Values from memcached

=cut

SV *
memcached_get(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        IN_OUT lmc_data_flags_t flags=0, \
        IN_OUT memcached_return error=0)
    CODE:
        /* rc is the return code from the preceeding mget */
        error = memcached_mget_by_key(ptr, NULL, 0, (const char * const*)&key, &XSauto_length_of_key, 1);
        RETVAL = _fetch_one_sv(ptr, &flags, &error);
    OUTPUT:
        RETVAL


SV *
memcached_get_by_key(Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        IN_OUT lmc_data_flags_t flags=0, \
        IN_OUT memcached_return error=0)
    CODE:
        error = memcached_mget_by_key(ptr, master_key, XSauto_length_of_master_key, (const char * const*)&key, &XSauto_length_of_key, 1);
        RETVAL = _fetch_one_sv(ptr, &flags, &error);
    OUTPUT:
        RETVAL


memcached_return
memcached_mget(Memcached__libmemcached ptr, SV *keys_rv)
    PREINIT:
        char **keys;
        size_t *key_length;
        unsigned int number_of_keys;
    CODE:
        if ((RETVAL = _prep_keys_lengths(ptr, keys_rv, &keys, &key_length, &number_of_keys)) == MEMCACHED_SUCCESS) {
            RETVAL = memcached_mget(ptr, (const char * const*)keys, key_length, number_of_keys);
        }
    OUTPUT:
        RETVAL

memcached_return
memcached_mget_by_key(Memcached__libmemcached ptr, lmc_key master_key, size_t length(master_key), SV *keys_rv)
    PREINIT:
        char **keys;
        size_t *key_length;
        unsigned int number_of_keys;
    CODE:
        if ((RETVAL = _prep_keys_lengths(ptr, keys_rv, &keys, &key_length, &number_of_keys)) == MEMCACHED_SUCCESS) {
            RETVAL = memcached_mget_by_key(ptr, master_key, XSauto_length_of_master_key, (const char * const*)keys, key_length, number_of_keys);
        }
    OUTPUT:
        RETVAL



lmc_value
memcached_fetch(Memcached__libmemcached ptr, \
        OUT lmc_key key, \
        IN_OUT lmc_data_flags_t flags=0, \
        IN_OUT memcached_return error=0)
    PREINIT:
        size_t key_length=0;
        size_t value_length=0;
        char key_buffer[MEMCACHED_MAX_KEY];
    INIT:
        key = key_buffer;
    CODE:
        RETVAL = memcached_fetch(ptr, key, &key_length, &value_length, &flags, &error);
    OUTPUT:
        RETVAL




=head2 Functions for Managing Results from memcached
/*
memcached_result_st *
memcached_fetch_result(Memcached__libmemcached ptr,\
                       memcached_result_st *result,\
                       memcached_return *error)
*/

=cut


=head2 Functions for Deleting Values from memcached

=cut

memcached_return
memcached_delete(Memcached__libmemcached ptr, \
        lmc_key key, size_t length(key), \
        lmc_expiration expiration= 0)

memcached_return
memcached_delete_by_key (Memcached__libmemcached ptr, \
        lmc_key master_key, size_t length(master_key), \
        lmc_key key, size_t length(key), \
        lmc_expiration expiration= 0)



=head2 Functions for Accessing Statistics from memcached

=cut


=head2 Miscellaneous Functions

=cut

memcached_return
memcached_verbosity(Memcached__libmemcached ptr, unsigned int verbosity)

memcached_return
memcached_flush(Memcached__libmemcached ptr, lmc_expiration expiration=0)

void
memcached_quit(Memcached__libmemcached ptr)

const char *
memcached_strerror(Memcached__libmemcached ptr, memcached_return rc)

const char *
memcached_lib_version()

=head2 Memcached::libmemcached Methods

=cut

IV
trace_level(Memcached__libmemcached ptr, IV level = IV_MIN)
    PREINIT:
        lmc_state_st* lmc_state;
    CODE:
        lmc_state = LMC_STATE_FROM_PTR(ptr);
        RETVAL = LMC_TRACE_LEVEL_FROM_PTR(ptr); /* return previous level */
        if (level != IV_MIN && lmc_state)
            lmc_state->trace_level = level;
    OUTPUT:
        RETVAL


SV *
errstr(Memcached__libmemcached ptr)
    ALIAS:
        memcached_errstr = 1
    PREINIT:
        lmc_state_st* lmc_state;
    CODE:
        if (!ptr)
            XSRETURN_UNDEF;
        PERL_UNUSED_VAR(ix);
        RETVAL = newSV(0);
        lmc_state = LMC_STATE_FROM_PTR(ptr);
        /* setup return value as a dualvar with int err code and string error message */
        sv_setiv(RETVAL, lmc_state->last_return);
        sv_setpv(RETVAL, memcached_strerror(ptr, lmc_state->last_return));
        if (lmc_state->last_return == MEMCACHED_ERRNO) {
            /* lmc_state->last_errno should be meaningful here but sometimes isn't */
            /* See https://rt.cpan.org/Ticket/Display.html?id=41299 */
            sv_catpvf(RETVAL, " %s", (lmc_state->last_errno) ? strerror(lmc_state->last_errno) : "(last_errno==0!)");
        }
        SvIOK_on(RETVAL); /* set as dualvar */
    OUTPUT:
        RETVAL


SV *
get(Memcached__libmemcached ptr, SV *key_sv)
    PREINIT:
        char *master_key = NULL;
        size_t master_key_len = 0;
        char *key;
        size_t key_len;
        memcached_return error;
        uint32_t flags;
    CODE:
        if (SvROK(key_sv) && SvTYPE(SvRV(key_sv)) == SVt_PVAV) {
            AV *av = (AV*)SvRV(key_sv);
            master_key = SvPV(AvARRAY(av)[0], master_key_len);
            key_sv = AvARRAY(av)[1];
            warn("get with array ref as key is deprecated");
        }
        key = SvPV(key_sv, key_len);
        error = memcached_mget_by_key(ptr, master_key, master_key_len, (const char * const*)&key, &key_len, 1);
        RETVAL = _fetch_one_sv(ptr, &flags, &error);
    OUTPUT:
        RETVAL


void
get_multi(Memcached__libmemcached ptr, ...)
    PREINIT:
        HV *hv = newHV();
        SV *dest_ref = sv_2mortal(newRV_noinc((SV*)hv));
        char **keys;
        size_t *key_length;
        unsigned int number_of_keys = --items;
        memcached_return ret;
        lmc_cb_context_st *lmc_cb_context;
    PPCODE:
        /* XXX does not support keys being [ $master_key, $key ] */
        lmc_cb_context = LMC_STATE_FROM_PTR(ptr)->cb_context;

        if (number_of_keys > lmc_cb_context->key_alloc_count)
            _prep_keys_buffer(lmc_cb_context, number_of_keys);
        keys       = lmc_cb_context->key_strings;
        key_length = lmc_cb_context->key_lengths;
        while (--items >= 0) {
            keys[items] = SvPV(ST(items+1), key_length[items]);
        }

        ret = memcached_mget(ptr, (const char * const*)keys, key_length, number_of_keys);
        _fetch_all_into_hashref(ptr, ret, hv);
        if (lmc_cb_context->lmc_state->trace_level)
            warn("get_multi of %d keys: mget %s, fetched %d",
                number_of_keys, memcached_strerror(ptr,ret), (int)lmc_cb_context->result_count);
        PUSHs(dest_ref);
        XSRETURN(1);



memcached_return
mget_into_hashref(Memcached__libmemcached ptr, SV *keys_ref, HV *dest_ref)
    ALIAS:
        memcached_mget_into_hashref = 1
    PREINIT:
        char **keys;
        size_t *key_length;
        unsigned int number_of_keys;
    CODE:
        PERL_UNUSED_VAR(ix);
        if ((RETVAL = _prep_keys_lengths(ptr, keys_ref, &keys, &key_length, &number_of_keys)) == MEMCACHED_SUCCESS) {
            RETVAL = memcached_mget(ptr, (const char * const*)keys, key_length, number_of_keys);
            RETVAL = _fetch_all_into_hashref(ptr, RETVAL, dest_ref);
        }
    OUTPUT:
        RETVAL


void
set_callback_coderefs(Memcached__libmemcached ptr, SV *set_cb, SV *get_cb)
    ALIAS:
        memcached_set_callback_coderefs = 1
    PREINIT:
        lmc_state_st *lmc_state;
    CODE:
        PERL_UNUSED_VAR(ix);
        if (SvOK(set_cb) && !(SvROK(set_cb) && SvTYPE(SvRV(set_cb)) == SVt_PVCV))
            croak("set_cb is not a reference to a subroutine");
        if (SvOK(get_cb) && !(SvROK(get_cb) && SvTYPE(SvRV(get_cb)) == SVt_PVCV))
            croak("get_cb is not a reference to a subroutine");
        lmc_state = LMC_STATE_FROM_PTR(ptr);
        sv_setsv(lmc_state->cb_context->set_cb, set_cb);
        sv_setsv(lmc_state->cb_context->get_cb, get_cb);


memcached_return
walk_stats(Memcached__libmemcached ptr, SV *stats_args, CV *cb)
    PREINIT:
        Memcached__libmemcached clone;
    CODE:
        if (LMC_TRACE_LEVEL_FROM_PTR(ptr) >= 2)
            warn("walk_stats(%s, %s)\n", SvPV_nolen(stats_args), SvPV_nolen((SV*)CvGV(cb)));

        clone = memcached_clone(NULL, ptr);
        memcached_behavior_set(clone, MEMCACHED_BEHAVIOR_BINARY_PROTOCOL, 0);

        ENTER;
        SAVETMPS;

        /* this local($_) assignment is to aid migration from the old api */
        SAVE_DEFSV; /* local($_) */
        DEFSV = sv_mortalcopy(stats_args);

        RETVAL = memcached_stat_execute(clone, SvPV_nolen(stats_args), _walk_stats_cb, cb);
        if (!LMC_RETURN_OK(RETVAL)) {
            LMC_RECORD_RETURN_ERR("memcached_stat_execute", ptr, RETVAL);
            LMC_STATE_FROM_PTR(ptr)->last_errno = memcached_last_error_errno(clone);
            memcached_free(clone);
            XSRETURN_NO;
        }
        memcached_free(clone);

        FREETMPS;
        LEAVE;
    OUTPUT:
        RETVAL

SV * get_server_for_key(Memcached__libmemcached ptr, char *key)
    CODE:
        memcached_return_t err;
        const memcached_instance_st *sp = memcached_server_by_key(ptr, key, strlen(key), &err);
        if (sp == NULL)
            XSRETURN_UNDEF;

        RETVAL = newSVpvf("%s:%d",
            memcached_server_name(sp),
            memcached_server_port(sp)
        );
        /* memcached_instance_free(sp); ??? */
    
    OUTPUT:
        RETVAL
