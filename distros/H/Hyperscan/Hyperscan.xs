#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_mess
#define NEED_mess_nocontext
#define NEED_mess_sv
#define NEED_vmess
#include "ppport.h"

#include "hs.h"

#include "const-c.inc"

typedef hs_database_t* Hyperscan__Database;
typedef hs_scratch_t* Hyperscan__Scratch;
typedef hs_stream_t* Hyperscan__Stream;

static
int
context_callback(unsigned int id, unsigned long long from, unsigned long long to, unsigned int flags, void *context)
{
    dTHXR;
    dSP;

    int count;
    bool rval;

    SV *callback = (SV*)context;

    if (callback != NULL) {
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 4);
        mPUSHu(id);
        mPUSHu(from);
        mPUSHu(to);
        mPUSHu(flags);
        PUTBACK;

        count = call_sv(callback, G_SCALAR);

        SPAGAIN;

        rval = SvTRUEx(POPs);

        PUTBACK;
        FREETMPS;
        LEAVE;

        return rval;
    }

    return 0;
}

static
const char*
hs_error_to_string(hs_error_t err)
{
    switch(err) {
        case HS_SUCCESS:
            return "HS_SUCCESS";
        case HS_INVALID:
            return "HS_INVALID";
        case HS_NOMEM:
            return "HS_NOMEM";
        case HS_SCAN_TERMINATED:
            return "HS_SCAN_TERMINATED";
        case HS_COMPILER_ERROR:
            return "HS_COMPILER_ERROR";
        case HS_DB_VERSION_ERROR:
            return "HS_DB_VERSION_ERROR";
        case HS_DB_PLATFORM_ERROR:
            return "HS_DB_PLATFORM_ERROR";
        case HS_DB_MODE_ERROR:
            return "HS_DB_MODE_ERROR";
        case HS_BAD_ALIGN:
            return "HS_BAD_ALIGN";
        case HS_BAD_ALLOC:
            return "HS_BAD_ALLOC";
        case HS_SCRATCH_IN_USE:
            return "HS_SCRATCH_IN_USE";
        case HS_ARCH_ERROR:
            return "HS_ARCH_ERROR";
        case HS_INSUFFICIENT_SPACE:
            return "HS_INSUFFICIENT_SPACE";
        case HS_UNKNOWN_ERROR:
            return "HS_UNKNOWN_ERROR";
        default:
            return "unknown error code";
    }
}

static
void*
newx_malloc(size_t size)
{
    void *ptr;
    Newx(ptr, size, char);
    return ptr;
}

static
void
my_safefree(void *ptr)
{
    Safefree(ptr);
}

MODULE = Hyperscan  PACKAGE = Hyperscan

INCLUDE: const-xs.inc

BOOT:
    {
        hs_error_t err;
        err = hs_set_allocator(newx_malloc, my_safefree);
        if (err != HS_SUCCESS) {
            croak("settings allocator failed (%s)", hs_error_to_string(err));
        }
    }

const char*
hs_version()

MODULE = Hyperscan  PACKAGE = Hyperscan::Database
PROTOTYPES: ENABLED

SV*
serialize(Hyperscan::Database self)
    PREINIT:
        char *bytes = NULL;
        size_t len;
        hs_error_t err;
    CODE:
        err = hs_serialize_database(self, &bytes, &len);
        if (err != HS_SUCCESS) {
            croak("failed to serialize database (%s)", hs_error_to_string(err));
        }
        RETVAL = newSVpvn(bytes, len);
        Safefree(bytes);
    OUTPUT: RETVAL

Hyperscan::Database
deserialize(const char *class, SV *bytes)
    PREINIT:
        char *raw = NULL;
        size_t len;
        hs_error_t err;
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = NULL;
        raw = SvPV(bytes, len);
        err = hs_deserialize_database(raw, len, &RETVAL);
        if (err != HS_SUCCESS) {
            croak("failed to deserialize database (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

size_t
stream_size(Hyperscan::Database self)
    PREINIT:
        hs_error_t err;
    CODE:
        RETVAL = 0;
        err = hs_stream_size(self, &RETVAL);
        if (err != HS_SUCCESS) {
            croak("failed to get stream size (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

size_t
size(Hyperscan::Database self)
    PREINIT:
        hs_error_t err;
    CODE:
        RETVAL = 0;
        err = hs_database_size(self, &RETVAL);
        if (err != HS_SUCCESS) {
            croak("failed to get database size (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

SV*
info(Hyperscan::Database self)
    PREINIT:
        char *info = NULL;
        hs_error_t err;
    CODE:
        err = hs_database_info(self, &info);
        if (err != HS_SUCCESS) {
            croak("failed to get info (%s)", hs_error_to_string(err));
        }
        RETVAL = newSVpv(info, 0);
    OUTPUT: RETVAL

Hyperscan::Database
compile(const char *class, const char *expression, unsigned int flags, unsigned int mode)
    PREINIT:
        hs_compile_error_t *compile_err = NULL;
        SV *msg = NULL;
        hs_error_t err;
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = NULL;
        err = hs_compile(expression, flags, mode, NULL, &RETVAL, &compile_err);
        if (err != HS_SUCCESS) {
            msg = mess("%s (%s)", compile_err->message, hs_error_to_string(err));
            hs_free_compile_error(compile_err);
            croak_sv(msg);
        }
    OUTPUT: RETVAL

Hyperscan::Database
compile_multi(const char *class, SV *expressions, SV *flags, SV *ids, unsigned int mode)
    PREINIT:
        int i;
        int elements;
        hs_compile_error_t *compile_err = NULL;
        SV *msg = NULL;
        AV *expr_arr = NULL, *flag_arr = NULL, *id_arr = NULL;
        const char **expression_values = NULL;
        unsigned int *flag_values = NULL;
        unsigned int *id_values = NULL;
        SV **tmp = NULL;
        hs_error_t err;
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = NULL;

        if (!SvROK(expressions) || SvTYPE(SvRV(expressions)) != SVt_PVAV) {
            croak("expressions must be an array ref");
        }
        if (!SvROK(flags) || SvTYPE(SvRV(flags)) != SVt_PVAV) {
            croak("flags must be an array ref");
        }
        if (!SvROK(ids) || SvTYPE(SvRV(ids)) != SVt_PVAV) {
            croak("ids must be an array ref");
        }
        expr_arr = (AV*)SvRV(expressions);
        elements = av_top_index(expr_arr) + 1;
        if (elements == 0) {
            croak("expressions must not be empty");
        }

        flag_arr = (AV*)SvRV(flags);
        if (elements != av_top_index(flag_arr) + 1) {
            croak("flags must have same number of elements as expressions");
        }

        id_arr = (AV*)SvRV(ids);
        if (elements != av_top_index(id_arr) + 1) {
            croak("ids must have same number of elements as expressions");
        }

        Newx(expression_values, elements+1, const char*);
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(expr_arr, i, 0);
            if (!SvOK(*tmp) || !SvPOK(*tmp)) {
                Safefree(expression_values);
                croak("expressions must be an array of strings");
            }
            expression_values[i] = SvPV_nolen(*tmp);
        }
        expression_values[elements] = NULL;

        Newx(flag_values, elements, unsigned int);
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(flag_arr, i, 0);
            if (!SvOK(*tmp) || !SvIOK(*tmp)) {
                Safefree(expression_values);
                Safefree(flag_values);
                croak("flags must be an array of ints");
            }
            flag_values[i] = SvIV(*tmp);
        }

        Newx(id_values, elements, unsigned int);
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(id_arr, i, 0);
            if (!SvOK(*tmp) || !SvIOK(*tmp)) {
                Safefree(expression_values);
                Safefree(flag_values);
                Safefree(id_values);
                croak("ids must be an array of ints");
            }
            id_values[i] = SvIV(*tmp);
        }

        err = hs_compile_multi(expression_values, flag_values, id_values, elements, mode, NULL, &RETVAL, &compile_err);
        Safefree(expression_values);
        Safefree(flag_values);
        Safefree(id_values);

        if (err != HS_SUCCESS) {
            msg = mess("%s (%s)", compile_err->message, hs_error_to_string(err));
            hs_free_compile_error(compile_err);
            croak_sv(msg);
        }
    OUTPUT: RETVAL

Hyperscan::Database
compile_ext_multi(const char *class, SV *expressions, SV *flags, SV *ids, SV *ext, unsigned int mode)
    PREINIT:
        int i, j;
        int elements;
        hs_compile_error_t *compile_err = NULL;
        SV *msg = NULL;
        AV *expr_arr = NULL, *flag_arr = NULL, *id_arr = NULL, *ext_arr = NULL;
        const char **expression_values = NULL;
        unsigned int *flag_values = NULL;
        unsigned int *id_values = NULL;
        const hs_expr_ext_t **ext_values = NULL;
        hs_expr_ext_t *ext_val = NULL;
        SV **tmp = NULL;
        HV *h = NULL;
        SV *v = NULL;
        char *k = NULL;
        I32 klen;
        hs_error_t err;
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = NULL;

        if (!SvROK(expressions) || SvTYPE(SvRV(expressions)) != SVt_PVAV) {
            croak("expressions must be an array ref");
        }
        if (!SvROK(flags) || SvTYPE(SvRV(flags)) != SVt_PVAV) {
            croak("flags must be an array ref");
        }
        if (!SvROK(ids) || SvTYPE(SvRV(ids)) != SVt_PVAV) {
            croak("ids must be an array ref");
        }
        if (!SvROK(ext) || SvTYPE(SvRV(ext)) != SVt_PVAV) {
            croak("ext must be an array ref");
        }

        expr_arr = (AV*)SvRV(expressions);
        elements = av_top_index(expr_arr) + 1;
        if (elements == 0) {
            croak("expressions must not be empty");
        }

        flag_arr = (AV*)SvRV(flags);
        if (elements != av_top_index(flag_arr) + 1) {
            croak("flags must have same number of elements as expressions");
        }

        id_arr = (AV*)SvRV(ids);
        if (elements != av_top_index(id_arr) + 1) {
            croak("ids must have same number of elements as expressions");
        }

        ext_arr = (AV*)SvRV(ext);
        if (elements != av_top_index(ext_arr) + 1) {
            croak("ext must have same number of elements as expressions");
        }

        Newx(expression_values, elements+1, const char*);
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(expr_arr, i, 0);
            if (!SvOK(*tmp) || !SvPOK(*tmp)) {
                Safefree(expression_values);
                croak("expressions must be an array of strings");
            }
            expression_values[i] = SvPV_nolen(*tmp);
        }
        expression_values[elements] = NULL;

        Newx(flag_values, elements, unsigned int);
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(flag_arr, i, 0);
            if (!SvOK(*tmp) || !SvIOK(*tmp)) {
                Safefree(expression_values);
                Safefree(flag_values);
                croak("flags must be an array of ints");
            }
            flag_values[i] = SvIV(*tmp);
        }

        Newx(id_values, elements, unsigned int);
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(id_arr, i, 0);
            if (!SvOK(*tmp) || !SvIOK(*tmp)) {
                Safefree(expression_values);
                Safefree(flag_values);
                Safefree(id_values);
                croak("ids must be an array of ints");
            }
            id_values[i] = SvIV(*tmp);
        }

        Newx(ext_values, elements, const hs_expr_ext_t*);
        for (i = 0; i < elements; i++) {
            Newxz(ext_val, 1, hs_expr_ext_t);
            ext_values[i] = ext_val;

            tmp = av_fetch(ext_arr, i, 0);
            if (!SvOK(*tmp)) {
                /* treat an undef as a noop */
                continue;
            }

            if (!SvROK(*tmp) || SvTYPE(SvRV(*tmp)) != SVt_PVHV) {
                Safefree(expression_values);
                Safefree(flag_values);
                Safefree(id_values);

                for (j = 0; j <= i; j++) {
                    Safefree(ext_values[i]);
                }
                Safefree(ext_values);

                croak("ext must be an array of hashes");
            }

            h = (HV*)SvRV(*tmp);
            hv_iterinit(h);
            while ((v = hv_iternextsv(h, &k, &klen)) != NULL) {
                if (memEQs(k, klen, "min_offset")) {
                    if (!SvOK(v) || !SvIOK(v)) {
                        msg = mess("ext hash key min_offset must be an int");
                    } else {
                        ext_val->flags |= HS_EXT_FLAG_MIN_OFFSET;
                        ext_val->min_offset = SvUV(v);
                        continue;
                    }
                } else if (memEQs(k, klen, "max_offset")) {
                    if (!SvOK(v) || !SvIOK(v)) {
                        msg = mess("ext hash key max_offset must be an int");
                    } else {
                        ext_val->flags |= HS_EXT_FLAG_MAX_OFFSET;
                        ext_val->max_offset = SvUV(v);
                        continue;
                    }
                } else if (memEQs(k, klen, "min_length")) {
                    if (!SvOK(v) || !SvIOK(v)) {
                        msg = mess("ext hash key min_length must be an int");
                    } else {
                        ext_val->flags |= HS_EXT_FLAG_MIN_LENGTH;
                        ext_val->min_length = SvUV(v);
                        continue;
                    }
                } else if (memEQs(k, klen, "edit_distance")) {
                    if (!SvOK(v) || !SvIOK(v)) {
                        msg = mess("ext hash key edit_distance must be an int");
                    } else {
                        ext_val->flags |= HS_EXT_FLAG_EDIT_DISTANCE;
                        ext_val->edit_distance = SvUV(v);
                        continue;
                    }
                } else if (memEQs(k, klen, "hamming_distance")) {
                    if (!SvOK(v) || !SvIOK(v)) {
                        msg = mess("ext hash key hamming_distance must be an int");
                    } else {
                        ext_val->flags |= HS_EXT_FLAG_HAMMING_DISTANCE;
                        ext_val->hamming_distance = SvUV(v);
                        continue;
                    }
                } else {
                    msg = mess("unsupported key %s in ext hash", k);
                }

                Safefree(expression_values);
                Safefree(flag_values);
                Safefree(id_values);

                for (j = 0; j <= i; j++) {
                    Safefree(ext_values[j]);
                }
                Safefree(ext_values);

                croak_sv(msg);
            }
        }

        err = hs_compile_ext_multi(expression_values, flag_values, id_values, ext_values, elements, mode, NULL, &RETVAL, &compile_err);
        Safefree(expression_values);
        Safefree(flag_values);
        Safefree(id_values);

        for (i = 0; i < elements; i++) {
            Safefree(ext_values[i]);
        }
        Safefree(ext_values);

        if (err != HS_SUCCESS) {
            msg = mess("%s (%s)", compile_err->message, hs_error_to_string(err));
            hs_free_compile_error(compile_err);
            croak_sv(msg);
        }
    OUTPUT: RETVAL

Hyperscan::Database
compile_lit(const char *class, SV *expression, unsigned flags, unsigned mode)
    PREINIT:
        STRLEN len;
        char *raw = NULL;
        hs_compile_error_t *compile_err = NULL;
        SV *msg = NULL;
        hs_error_t err;
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = NULL;
        if (!SvOK(expression) || !SvPOK(expression)) {
            croak("expression must be a string");
        }
        raw = SvPV(expression, len);
        err = hs_compile_lit(raw, flags, len, mode, NULL, &RETVAL, &compile_err);
        if (err != HS_SUCCESS) {
            msg = mess("%s (%s)", compile_err->message, hs_error_to_string(err));
            hs_free_compile_error(compile_err);
            croak_sv(msg);
        }
    OUTPUT: RETVAL

Hyperscan::Database
compile_lit_multi(const char *class, SV *expressions, SV *flags, SV *ids, unsigned mode)
    PREINIT:
        int i;
        STRLEN len;
        int elements;
        hs_compile_error_t *compile_err = NULL;
        SV *msg = NULL;
        AV *expr_arr = NULL, *flag_arr = NULL, *id_arr = NULL;
        const char **expression_values = NULL;
        size_t *len_values = NULL;
        unsigned int *flag_values = NULL;
        unsigned int *id_values = NULL;
        SV **tmp = NULL;
        hs_error_t err;
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = NULL;

        if (!SvROK(expressions) || SvTYPE(SvRV(expressions)) != SVt_PVAV) {
            croak("expressions must be an array ref");
        }
        if (!SvROK(flags) || SvTYPE(SvRV(flags)) != SVt_PVAV) {
            croak("flags must be an array ref");
        }
        if (!SvROK(ids) || SvTYPE(SvRV(ids)) != SVt_PVAV) {
            croak("ids must be an array ref");
        }

        expr_arr = (AV*)SvRV(expressions);
        elements = av_top_index(expr_arr) + 1;
        if (elements == 0) {
            croak("expressions must not be empty");
        }

        flag_arr = (AV*)SvRV(flags);
        if (elements != av_top_index(flag_arr) + 1) {
            croak("flags must have same number of elements as expressions");
        }

        id_arr = (AV*)SvRV(ids);
        if (elements != av_top_index(id_arr) + 1) {
            croak("ids must have same number of elements as expressions");
        }

        Newx(expression_values, elements+1, const char*);
        Newx(len_values, elements, size_t);
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(expr_arr, i, 0);
            if (!SvOK(*tmp) || !SvPOK(*tmp)) {
                Safefree(expression_values);
                Safefree(len_values);
                croak("expressions must be an array of strings");
            }
            expression_values[i] = SvPV(*tmp, len);
            len_values[i] = len;
        }
        expression_values[elements] = NULL;

        Newx(flag_values, elements, unsigned int);
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(flag_arr, i, 0);
            if (!SvOK(*tmp) || !SvIOK(*tmp)) {
                Safefree(expression_values);
                Safefree(len_values);
                Safefree(flag_values);
                croak("flags must be an array of ints");
            }
            flag_values[i] = SvIV(*tmp);
        }

        Newx(id_values, elements, unsigned int);
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(id_arr, i, 0);
            if (!SvOK(*tmp) || !SvIOK(*tmp)) {
                Safefree(expression_values);
                Safefree(len_values);
                Safefree(flag_values);
                Safefree(id_values);
                croak("ids must be an array of ints");
            }
            id_values[i] = SvIV(*tmp);
        }

        err = hs_compile_lit_multi(expression_values, flag_values, id_values, len_values, elements, mode, NULL, &RETVAL, &compile_err);
        Safefree(expression_values);
        Safefree(len_values);
        Safefree(flag_values);
        Safefree(id_values);

        if (err != HS_SUCCESS) {
            msg = mess("%s (%s)", compile_err->message, hs_error_to_string(err));
            hs_free_compile_error(compile_err);
            croak_sv(msg);
        }
    OUTPUT: RETVAL

Hyperscan::Stream
open_stream(Hyperscan::Database self, unsigned int flags=0)
    PREINIT:
        hs_error_t err;
    CODE:
        RETVAL = NULL;
        err = hs_open_stream(self, flags, &RETVAL);
        if (err != HS_SUCCESS) {
            croak("error opening stream (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

int
scan(Hyperscan::Database self, SV *data, unsigned int flags=0, Hyperscan::Scratch scratch=NULL, SV *onEvent=NULL)
    PREINIT:
        STRLEN len;
        char *raw = NULL;
        hs_error_t err;
    CODE:
        if (!SvOK(data) || !SvPOK(data)) {
            croak("data must be a string");
        }
        raw = SvPV(data, len);
        PUTBACK;
        err = hs_scan(self, raw, len, flags, scratch, context_callback, onEvent);
        SPAGAIN;
        if (err == HS_SUCCESS) {
            RETVAL = 0;
        } else if (err == HS_SCAN_TERMINATED) {
            RETVAL = 1;
        } else {
            croak("scanning failed (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

int
scan_vector(Hyperscan::Database self, SV *data, unsigned int flags=0, Hyperscan::Scratch scratch=NULL, SV *onEvent=NULL)
    PREINIT:
        int i;
        AV *data_arr = NULL;
        int count;
        const char **data_values = NULL;
        unsigned int *len_values = NULL;
        SV **tmp = NULL;
        STRLEN len;
        hs_error_t err;
    CODE:
        if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVAV) {
            croak("data must be an array ref");
        }

        data_arr = (AV*)SvRV(data);
        count = av_top_index(data_arr) + 1;
        if (count == 0) {
            croak("data must not be empty");
        }

        Newx(data_values, count, const char*);
        Newx(len_values, count, unsigned int);

        for (i = 0; i < count; i++) {
            tmp = av_fetch(data_arr, i, 0);
            if (!SvOK(*tmp) || !SvPOK(*tmp)) {
                Safefree(data_values);
                Safefree(len_values);
                croak("data must be an array of strings");
            }
            data_values[i] = SvPV(*tmp, len);
            len_values[i] = len;
        }

        PUTBACK;
        err = hs_scan_vector(self, data_values, len_values, count, flags, scratch, context_callback, onEvent);
        SPAGAIN;

        Safefree(data_values);
        Safefree(len_values);

        if (err == HS_SUCCESS) {
            RETVAL = 0;
        } else if (err == HS_SCAN_TERMINATED) {
            RETVAL = 1;
        } else {
            croak("scanning failed (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

Hyperscan::Scratch
alloc_scratch(Hyperscan::Database self)
    PREINIT:
        hs_error_t err;
    CODE:
        RETVAL = NULL;
        err = hs_alloc_scratch(self, &RETVAL);
        if (err != HS_SUCCESS) {
            croak("error allocating scratch (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

void
DESTROY(Hyperscan::Database self)
    PREINIT:
        hs_error_t err;
    CODE:
        err = hs_free_database(self);
        if (err != HS_SUCCESS) {
            croak("freeing database failed (%s)", hs_error_to_string(err));
        }

MODULE = Hyperscan  PACKAGE = Hyperscan::Scratch

Hyperscan::Scratch
clone(Hyperscan::Scratch self)
    PREINIT:
        hs_error_t err;
    CODE:
        RETVAL = NULL;
        err = hs_clone_scratch(self, &RETVAL);
        if (err != HS_SUCCESS) {
            croak("error cloning scratch (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

size_t
size(Hyperscan::Scratch scratch)
    PREINIT:
        hs_error_t err;
    CODE:
        RETVAL = 0;
        err = hs_scratch_size(scratch, &RETVAL);
        if (err != HS_SUCCESS) {
            croak("error getting scratch size (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

void
DESTROY(Hyperscan::Scratch self)
    PREINIT:
        hs_error_t err;
    CODE:
        err = hs_free_scratch(self);
        if (err != HS_SUCCESS) {
            croak("freeing scratch failed (%s)", hs_error_to_string(err));
        }

MODULE = Hyperscan  PACKAGE = Hyperscan::Stream

int
scan(Hyperscan::Stream self, SV *data, unsigned int flags=0, Hyperscan::Scratch scratch=NULL, SV *onEvent=NULL)
    PREINIT:
        STRLEN len;
        char *raw = NULL;
        hs_error_t err;
    CODE:
        if (!SvOK(data) || !SvPOK(data)) {
            croak("data must be a string");
        }
        raw = SvPV(data, len);
        PUTBACK;
        err = hs_scan_stream(self, raw, len, flags, scratch, context_callback, onEvent);
        SPAGAIN;
        if (err == HS_SUCCESS) {
            RETVAL = 0;
        } else if (err == HS_SCAN_TERMINATED) {
            RETVAL = 1;
        } else {
            croak("scanning failed (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

void
reset(Hyperscan::Stream self, unsigned int flags=0, Hyperscan::Scratch scratch=NULL, SV *onEvent=NULL)
    PREINIT:
        hs_error_t err;
    CODE:
        PUTBACK;
        err = hs_reset_stream(self, flags, scratch, context_callback, onEvent);
        SPAGAIN;
        if (err != HS_SUCCESS) {
            croak("error reseting stream (%s)", hs_error_to_string(err));
        }

Hyperscan::Stream
copy(Hyperscan::Stream self)
    PREINIT:
        hs_error_t err;
    CODE:
        RETVAL = NULL;
        err = hs_copy_stream(&RETVAL, self);
        if (err != HS_SUCCESS) {
            croak("error copying stream (%s)", hs_error_to_string(err));
        }
    OUTPUT: RETVAL

void
DESTROY(Hyperscan::Stream self)
    PREINIT:
        hs_error_t err;
    CODE:
        err = hs_close_stream(self, NULL, NULL, NULL);
        if (err != HS_SUCCESS) {
            croak("error closing stream (%s)", hs_error_to_string(err));
        }
