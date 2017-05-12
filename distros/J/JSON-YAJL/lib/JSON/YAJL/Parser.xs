#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <yajl_lex.h>
#include <yajl_parse.h>
#include <yajl_parser.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"

typedef yajl_handle JSON__YAJL__Parser;

int DEBUG = 0;

void callback_call(SV* hashref, unsigned int index) {
    HV* hash;
    SV** array_p;
    SV* arrayref;
    AV* array;
    SV** callback_p;
    SV* callbackref;
    SV* callback;
    dSP;

    if (!SvOK((SV*) hashref)) {
        Perl_croak(aTHX_ "YAJL: hashref is not defined");
    } else {
        DEBUG && printf("  hashref is defined\n");
    }
    if (!SvROK((SV*) hashref)) {
        Perl_croak(aTHX_ "YAJL: hashref is not a reference");
    } else {
        DEBUG && printf("  hashref is a reference\n");
    }
    hash = (HV*) SvRV((SV*) hashref);
    if (SvTYPE(hash) != SVt_PVHV) {
        Perl_croak(aTHX_ "YAJL: hash is not a PVHV");
    } else {
        DEBUG && printf("  hash is a PVHV\n");
    }
    array_p = hv_fetchs(hash, "array", 0);
    if (array_p == NULL) {
        Perl_croak(aTHX_ "YAJL: array_p is NULL");
    } else {
        DEBUG && printf("  array_p is not NULL\n");
    }
    arrayref = (SV*) *array_p;
    if (!SvROK(arrayref)) {
        printf("type is %i\n", SvTYPE(arrayref));
        Perl_croak(aTHX_ "YAJL: arrayref is not a reference");
    } else {
        DEBUG && printf("  arrayref is a reference\n");
    }
    array = (AV*) SvRV(arrayref);
    if (SvTYPE(array) != SVt_PVAV) {
        printf("type is %i\n", SvTYPE(array));
        Perl_croak(aTHX_ "YAJL: array is not a PVAV");
    } else {
        DEBUG && printf("  array is a PVAV\n");
    }
    callback_p =  av_fetch(array, index, 0);
    if (callback_p == NULL) {
        DEBUG && printf("  nothing in array slot\n");
        return;
    } else {
        DEBUG && printf("  something in array slot\n");
    }
    callbackref = (SV*) *callback_p;
    if (!SvROK((SV*) callbackref)) {
        Perl_croak(aTHX_ "YAJL: callbackref is not a reference");
    } else {
        DEBUG && printf("  callbackref is a reference\n");
    }

    callback = (SV*) SvRV((SV*) callbackref);
    if (SvTYPE(callback) != SVt_PVCV) {
        Perl_croak(aTHX_ "YAJL: callback is not a PVCV");
    } else {
        DEBUG && printf("  callback is a PVCV\n");
    }
    DEBUG && printf("  about to call callback\n");
    call_sv(callback, G_DISCARD);
    FREETMPS;
    LEAVE;
}

static int callback_null(void * hashref) {
    DEBUG && printf("null\n");
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    callback_call((SV*) hashref, 0);
    return 1;
}

static int callback_boolean(void * hashref, int boolean) {
    DEBUG && printf("boolean %i\n", boolean);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(boolean)));
    PUTBACK;
    callback_call((SV*) hashref, 1);
    return 1;
}

static int callback_number(void * hashref, const char * s, size_t l) {
    DEBUG && printf("number %.*s\n", (int)l, s);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(s, l)));
    PUTBACK;
    callback_call((SV*) hashref, 4);
    return 1;
}

static int callback_string(void * hashref, const unsigned char * s, size_t l) {
    DEBUG && printf("string %.*s\n", (int)l, s);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv((char *)s, l)));
    PUTBACK;
    callback_call((SV*) hashref, 5);
    return 1;
}

static int callback_map_open(void * hashref) {
    DEBUG && printf("map_open\n");
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    callback_call((SV*) hashref, 6);
    return 1;
}

static int callback_map_key(void * hashref, const unsigned char * s, size_t l) {
    DEBUG && printf("map_key %.*s\n", (int)l, s);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv((char *)s, l)));
    PUTBACK;
    callback_call((SV*) hashref, 7);
    return 1;
}

static int callback_map_close(void * hashref) {
    DEBUG && printf("map_close\n");
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    callback_call((SV*) hashref, 8);
    return 1;
}

static int callback_array_open(void * hashref) {
    DEBUG && printf("array_open\n");
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    callback_call((SV*) hashref, 9);
    return 1;
}

static int callback_array_close(void * hashref) {
    DEBUG && printf("array_close\n");
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    callback_call((SV*) hashref, 10);
    return 1;
}

static yajl_callbacks callbacks = {
    callback_null,
    callback_boolean,
    NULL,
    NULL,
    callback_number,
    callback_string,
    callback_map_open,
    callback_map_key,
    callback_map_close,
    callback_array_open,
    callback_array_close,
    };

MODULE = JSON::YAJL::Parser		PACKAGE = JSON::YAJL::Parser

JSON::YAJL::Parser new(package, unsigned int allowComments = 0, unsigned int checkUTF8 = 0, SV* arrayref)
CODE:
    yajl_handle parser;
    AV* array;
    HV *hash = newHV();
    (void)hv_stores(hash, "data", newSVpv("", 0));
    SvREFCNT_inc_void(arrayref);
    if (!SvROK(arrayref)) {
        printf("type is %i\n", SvTYPE(arrayref));
        Perl_croak(aTHX_ "YAJL: arrayref is not a reference");
    } else {
        DEBUG && printf("arrayref is a reference\n");
    }
    array = (AV*) SvRV(arrayref);
    if (SvTYPE(array) != SVt_PVAV) {
        printf("type is %i\n", SvTYPE(array));
        Perl_croak(aTHX_ "YAJL: array is not a PVAV");
    } else {
        DEBUG && printf("array is an PVAV\n");
    }
    (void)hv_stores(hash, "array", arrayref);
    SV *hashref = newRV_noinc((SV*)hash);
    parser = yajl_alloc(&callbacks, NULL, (void *) hashref);
    yajl_config(parser, yajl_allow_comments, allowComments);
    yajl_config(parser, yajl_dont_validate_strings, !checkUTF8);
    RETVAL = parser;
OUTPUT:
    RETVAL

void parse(JSON::YAJL::Parser parser, SV* data)
CODE:
    const char * jsonText;
    unsigned int jsonTextLength;
    yajl_status status;
    unsigned char * error;
    SV* hashref;
    HV* hash;
    SV** dataref;
    jsonText = SvPV_nolen(data);
    jsonTextLength = SvCUR(data);
    status = yajl_parse(parser, (unsigned char*)jsonText, jsonTextLength);
    if (status != yajl_status_ok) {
        error = yajl_get_error(parser, 1, (unsigned char*)jsonText, jsonTextLength);
        Perl_croak(aTHX_ "%s", error);
        yajl_free_error(parser, error);
    } else {
        hashref = (SV*) parser->ctx;
        hash = (HV*) SvRV(hashref);
        (void)hv_stores(hash, "data", data);
    }

void parse_complete(JSON::YAJL::Parser parser)
CODE:
    yajl_status status;
    unsigned char * error;
    const char * jsonText;
    unsigned int jsonTextLength;
    SV* hashref;
    HV* hash;
    SV** dataref;
    SV* data;
    status = yajl_complete_parse(parser);
    if (status != yajl_status_ok) {
        hashref = (SV*) parser->ctx;
        hash = (HV*) SvRV(hashref);
        dataref = hv_fetchs(hash, "data", 0);
        data = (SV*) *dataref;
        jsonText = SvPV_nolen(data);
        jsonTextLength = SvCUR(data);
        error = yajl_get_error(parser, 1, (unsigned char*)jsonText, jsonTextLength);
        Perl_croak(aTHX_ "%s", error);
        yajl_free_error(parser, error);
    }

void DESTROY(JSON::YAJL::Parser parser)
CODE:
    SV* hashref;
    HV* hash;
    SV** array_p;
    SV* arrayref;

    hashref = (SV*) parser->ctx;
    hash = (HV*) SvRV(hashref);
    array_p = hv_fetchs(hash, "array", 0);
    if (array_p == NULL) {
        Perl_croak(aTHX_ "YAJL: DESTROY array_p is NULL");
    } else {
        DEBUG && printf("destroy array_p is not NULL\n");
    }
    arrayref = (SV*) *array_p;
    if (!SvROK(arrayref)) {
        printf("type is %i\n", SvTYPE(arrayref));
        Perl_croak(aTHX_ "YAJL: DESTROY arrayref is not a reference");
    } else {
        DEBUG && printf("destroy arrayref is a reference\n");
    }
    SvREFCNT_dec(arrayref);
    DEBUG && printf("decreased refcount of arrayref\n");
    yajl_free(parser);
