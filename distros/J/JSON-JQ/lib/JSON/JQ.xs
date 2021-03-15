/***************************************************************************
    copyright            : (C) 2021 - 2021 by Dongxu Ma
    email                : dongxu@cpan.org

    This library is free software; you can redistribute it and/or modify
    it under MIT license. Refer to LICENSE within the package root folder
    for full copyright.

 ***************************************************************************/

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>

#include "jq.h"
#include "jv.h"
// TODO: get version from Alien::LibJQ cflags
#define JQ_VERSION "1.6"

// utility functions for type marshaling
// they are not XS code
jv my_jv_input(pTHX_ void * arg) {
    if (arg == NULL) {
        return jv_null();
    }
    SV * const p_sv = arg;
    SvGETMAGIC(p_sv);
    if (SvTYPE(p_sv) == SVt_NULL || (SvTYPE(p_sv) < SVt_PVAV && !SvOK(p_sv))) {
        // undef or JSON::null()
        return jv_null();
    }
    else if (SvROK(p_sv) && SvTYPE(SvRV(p_sv)) == SVt_IV) {
        // boolean: \0 or \1, equilvalent of $JSON::PP::true, $JSON::PP::false
        //fprintf(stderr, "got boolean value: %s\n", SvTRUE(SvRV(p_sv)) ? "True" : "False");
        return jv_bool((bool)SvTRUE(SvRV(p_sv)));
    }
    else if (SvROK(p_sv) && sv_derived_from(p_sv, "JSON::PP::Boolean")) {
        // boolean: $JSON::PP::true and $JSON::PP::false
        return jv_bool((bool)SvTRUE(SvRV(p_sv)));
    }
    else if (SvIOK(p_sv)) {
        // integer
        return jv_number((int)SvIV(p_sv));
    }
    else if (SvUOK(p_sv)) {
        // unsigned int
        return jv_number((unsigned int)SvUV(p_sv));
    }
    else if (SvNOK(p_sv)) {
        // double
        return jv_number((double)SvNV(p_sv));
    }
    else if (SvPOK(p_sv)) {
        // string
        STRLEN len;
        char * p_pv = SvPVutf8(p_sv, len);
        return jv_string_sized(p_pv, len);
    }
    else if (SvROK(p_sv) && SvTYPE(SvRV(p_sv)) == SVt_PVAV) {
        // array
        jv jval = jv_array();
        AV * p_av = (AV *)SvRV(p_sv);
        SSize_t len = av_len(p_av);
        if (len < 0) {
            return jval;
        }
        for (SSize_t i = 0; i <= len; i++) {
            jval = jv_array_append(jval, my_jv_input(aTHX_ *av_fetch(p_av, i, 0)));
        }
        return jval;
    }
    else if (SvROK(p_sv) && SvTYPE(SvRV(p_sv)) == SVt_PVHV) {
        // hash
        jv jval = jv_object();
        HV * p_hv = (HV *)SvRV(p_sv);
        I32 len = hv_iterinit(p_hv);
        for (I32 i = 0; i < len; i++) {
            char * key = NULL;
            I32 klen = 0;
            SV * val = hv_iternextsv(p_hv, &key, &klen);
            jval = jv_object_set(jval, jv_string_sized(key, klen), my_jv_input(aTHX_ val));
        }
        return jval;
    }
    else {
        // not supported
        croak("cannot convert perl object to json format: SvTYPE == %i", SvTYPE(p_sv));
    }
    // NOREACH
}

void * my_jv_output(pTHX_ jv jval) {
    jv_kind kind = jv_get_kind(jval);
    if (kind == JV_KIND_NULL) {
        // null
        return newSV(0);
    }
    else if (kind == JV_KIND_FALSE) {
        // boolean: false
        // NOTE: get_sv("JSON::PP::false") doesn't work
        SV * sv_false = newSV(0);
        //fprintf(stderr, "set boolean: False\n");
        return sv_setref_iv(sv_false, "JSON::PP::Boolean", 0);
    }
    else if (kind == JV_KIND_TRUE) {
        // boolean: true
        SV * sv_true = newSV(0);
        //fprintf(stderr, "set boolean: True\n");
        return sv_setref_iv(sv_true, "JSON::PP::Boolean", 1);
    }
    else if (kind == JV_KIND_NUMBER) {
        // number
        double val = jv_number_value(jval);
        SV * p_sv = newSV(0);
        if (jv_is_integer(jval)) {
            sv_setiv(p_sv, (int)val);
        }
        else {
            sv_setnv(p_sv, val);
        }
        return p_sv;
    }
    else if (kind == JV_KIND_STRING) {
        // string
        return newSVpvn_utf8(jv_string_value(jval), jv_string_length_bytes(jval), 1);
    }
    else if (kind == JV_KIND_ARRAY) {
        // array
        AV * p_av = newAV();
        SSize_t len = (SSize_t)jv_array_length(jv_copy(jval));
        av_extend(p_av, len - 1);
        for (SSize_t i = 0; i < len; i++) {
            jv val = jv_array_get(jv_copy(jval), i);
            av_push(p_av, (SV *)my_jv_output(aTHX_ val));
            jv_free(val);
        }
        return newRV_noinc((SV *)p_av);
    }
    else if (kind == JV_KIND_OBJECT) {
        // hash
        HV * p_hv = newHV();
        int iter = jv_object_iter(jval);
        while (jv_object_iter_valid(jval, iter)) {
            jv key = jv_object_iter_key(jval, iter);
            jv val = jv_object_iter_value(jval, iter);
            if (jv_get_kind(key) != JV_KIND_STRING) {
                croak("cannot take non-string type as hash key: JV_KIND == %i", jv_get_kind(key));
            }
            const char * k = jv_string_value(key);
            int klen = jv_string_length_bytes(key);
            SV * v = (SV *)my_jv_output(aTHX_ val);
            hv_store(p_hv, k, klen, v, 0);
            jv_free(key);
            jv_free(val);
            iter = jv_object_iter_next(jval, iter);
        }
        return newRV_noinc((SV *)p_hv);
    }
    else {
        croak("un-supported jv object type: JV_KIND == %i", kind);
    }
    // NOREACH
}

static void my_error_cb(void * errors, jv jerr) {
    dTHX;
    av_push((AV *)errors, newSVpvn_utf8(jv_string_value(jerr), jv_string_length_bytes(jerr), 1));
}

static void my_debug_cb(void * data, jv input) {
    dTHX;
    int dumpopts = *(int *)data;
    jv_dumpf(JV_ARRAY(jv_string("DEBUG:"), input), stderr, dumpopts);
    fprintf(stderr, "\n");
}

inline void assert_isa(pTHX_ SV * self) {
    if (!sv_isa(self, "JSON::JQ")) {
        croak("self is not a JSON::JQ object");
    }
}

// copied from main.c
static const char *skip_shebang(const char *p) {
    if (strncmp(p, "#!", sizeof("#!") - 1) != 0)
        return p;
    const char *n = strchr(p, '\n');
    if (n == NULL || n[1] != '#')
        return p;
    n = strchr(n + 1, '\n');
    if (n == NULL || n[1] == '#' || n[1] == '\0' || n[-1] != '\\' || n[-2] == '\\')
        return p;
    n = strchr(n + 1, '\n');
    if (n == NULL)
        return p;
    return n+1;
}

MODULE = JSON::JQ              PACKAGE = JSON::JQ

PROTOTYPES: DISABLE

int
JV_PRINT_INDENT_FLAGS(n)
        int n
    CODE:
        RETVAL = JV_PRINT_INDENT_FLAGS(n);
    OUTPUT:
        RETVAL

void
_init(self)
        HV * self
    INIT:
        jq_state * _jq = NULL;
        SV * sv_jq;
        HV * hv_attr;
        char * script;
        AV * av_err;
        int compiled = 0;
    CODE:
        assert_isa(aTHX_ ST(0));
        // step 1. initialize
        _jq = jq_init();
        if (_jq == NULL) {
            croak("cannot malloc jq engine");
        }
        else {
            sv_jq = newSV(0);
            sv_setiv(sv_jq, PTR2IV(_jq));
            SvREADONLY_on(sv_jq);
            hv_stores(self, "_jq", sv_jq);
        }
        // step 2. set error and debug callbacks
        av_err = (AV *)SvRV(*hv_fetchs(self, "_errors", 0));
        jq_set_error_cb(_jq, my_error_cb, av_err);
        int dumpopts = (int)SvIV(*hv_fetchs(self, "_dumpopts", 0));
        jq_set_debug_cb(_jq, my_debug_cb, &dumpopts);
        // step 3. set initial attributes
        hv_attr = (HV *)SvRV(*hv_fetchs(self, "_attribute", 0));
        I32 len = hv_iterinit(hv_attr);
        for (I32 i = 0; i < len; i++) {
            char * key = NULL;
            I32 klen = 0;
            SV * val = hv_iternextsv(hv_attr, &key, &klen);
            jq_set_attr(_jq, jv_string_sized(key, klen), my_jv_input(aTHX_ val));
        }
        // set JQ_VERSION
        jq_set_attr(_jq, jv_string("VERSION_DIR"), jv_string(JQ_VERSION));
        // step 4. compile
        jv args = my_jv_input(aTHX_ *hv_fetchs(self, "variable", 0));
        if (hv_exists(self, "script_file", 11)) {
            jv data = jv_load_file(SvPV_nolen(*hv_fetchs(self, "script_file", 0)), 1);
            if (!jv_is_valid(data)) {
                data = jv_invalid_get_msg(data);
                my_error_cb(av_err, data);
                jv_free(data);
                XSRETURN_NO;
            }
            compiled = jq_compile_args(_jq, skip_shebang(jv_string_value(data)), args);
            jv_free(data);
        }
        else {
            script = SvPV_nolen(*hv_fetchs(self, "script", 0));
            compiled = jq_compile_args(_jq, script, args);

        }
        if (compiled) {
            if (SvTRUE(get_sv("JSON::JQ::DUMP_DISASM", 0))) {
                jq_dump_disassembly(_jq, 0);
                printf("\n");
            }
            XSRETURN_YES;
        }
        else {
            jv_free(args);
            // jq_teardown(&_jq); // no need to call destructor here, DESTROY will do
            XSRETURN_NO;
        }

int
_process(self, sv_input, av_output)
        HV * self
        SV * sv_input
        AV * av_output
    INIT:
        jq_state * _jq = NULL;
        SV * sv_jq;
        AV * av_err;
    CODE:
        assert_isa(aTHX_ ST(0));
        sv_jq = *hv_fetchs(self, "_jq", 0);
        _jq = INT2PTR(jq_state *, SvIV(sv_jq));
        jv jv_input = my_jv_input(aTHX_ sv_input);
        int jq_flags = (int)SvIV(*hv_fetchs(self, "jq_flags", 0));
        // logic from static int process(jq state *jq jv value, int flags, int dumpopts) in main.c
        jq_start(_jq, jv_input, jq_flags);
        jv result;
        // clear previous call errors
        av_err = (AV *)SvRV(*hv_fetchs(self, "_errors", 0));
        av_clear(av_err);
        int ret = 14;
        while (jv_is_valid(result = jq_next(_jq))) {
            av_push(av_output, (SV *)my_jv_output(aTHX_ result));
            if (jv_get_kind(result) == JV_KIND_FALSE || jv_get_kind(result) == JV_KIND_NULL) {
                ret = 11;
            }
            else {
                ret = 0;
            }
            jv_free(result);
        }
        if (jq_halted(_jq)) {
            // jq program invoked `halt` or `halt_error`
            jv exit_code = jq_get_exit_code(_jq);
            if (!jv_get_kind(exit_code)) {
                ret = 0;
            }
            else if (jv_get_kind(exit_code) == JV_KIND_NUMBER) {
                ret = jv_number_value(exit_code);
            }
            else {
                ret = 5;
            }
            jv_free(exit_code);
            jv error_message = jq_get_error_message(_jq);
            if (jv_get_kind(error_message) == JV_KIND_STRING) {
                my_error_cb(av_err, error_message);
            }
            else if (jv_get_kind(error_message) == JV_KIND_NULL) {
                // halt with no output
            }
            else if (jv_is_valid(error_message)) {
                error_message = jv_dump_string(jv_copy(error_message), 0);
                my_error_cb(av_err, error_message);
            }
            else {
                // no message; use --debug-trace to see a message
            }
            jv_free(error_message);
        }
        else if (jv_invalid_has_msg(jv_copy(result))) {
            // uncaught jq exception
            jv msg = jv_invalid_get_msg(jv_copy(result));
            jv input_pos = jq_util_input_get_position(_jq);
            if (jv_get_kind(msg) == JV_KIND_STRING) {
                av_push(av_err, newSVpvf("jq: error (at %s): %s", jv_string_value(input_pos), jv_string_value(msg)));
            }
            else {
                msg = jv_dump_string(msg, 0);
                av_push(av_err, newSVpvf("jq: error (at %s) (not a string): %s", jv_string_value(input_pos), jv_string_value(msg)));
            }
            ret = 5;
            jv_free(input_pos);
            jv_free(msg);
        }
        jv_free(result);
        RETVAL = ret;
    OUTPUT:
        RETVAL

void
DESTROY(self)
        HV * self
    INIT:
        jq_state * _jq = NULL;
        SV * sv_jq;
    CODE:
        assert_isa(aTHX_ ST(0));
        sv_jq = *hv_fetchs(self, "_jq", 0);
        _jq = INT2PTR(jq_state *, SvIV(sv_jq));
        if (_jq != NULL) {
            if (SvTRUE(get_sv("JSON::JQ::DEBUG", 0))) {
                fprintf(stderr, "destroying jq object: %i\n", _jq);
            }
            jq_teardown(&_jq);
        }