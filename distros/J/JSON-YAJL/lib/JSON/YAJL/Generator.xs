#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <yajl_gen.h>     
#include <stdio.h>  
#include <stdlib.h>  
#include <string.h>
#define NEED_newSVpvn_flags
#include "ppport.h"

typedef yajl_gen JSON__YAJL__Generator;

void croak_on_status(yajl_gen_status s) {
    if (s == yajl_gen_status_ok) {
    } else if (s == yajl_gen_keys_must_be_strings) {
        Perl_croak(aTHX_ "YAJL: Keys must be strings");
    } else if (s == yajl_max_depth_exceeded) {
        Perl_croak(aTHX_ "YAJL: Max depth exceeded");
    } else if (s == yajl_gen_in_error_state) {
        Perl_croak(aTHX_ "YAJL: In error state");
    } else if (s == yajl_gen_generation_complete) {
        Perl_croak(aTHX_ "YAJL: Generation complete");
    } else if (s == yajl_gen_invalid_number) {
        Perl_croak(aTHX_ "YAJL: Invalid number");
    } else if (s == yajl_gen_no_buf) {
        Perl_croak(aTHX_ "YAJL: No buf");
    } else {
        Perl_croak(aTHX_ "YAJL: Unknown status");
    }
}

MODULE = JSON::YAJL::Generator		PACKAGE = JSON::YAJL::Generator

JSON::YAJL::Generator new(package, unsigned int beautify = 0, const char * indentString = "    ")
CODE:
    yajl_gen g;
    g = yajl_gen_alloc(NULL);
    yajl_gen_config(g, yajl_gen_beautify, beautify);
    yajl_gen_config(g, yajl_gen_indent_string, indentString);
    RETVAL = g;
OUTPUT:
    RETVAL

void integer(JSON::YAJL::Generator g, long int n)
CODE:
    croak_on_status(yajl_gen_integer(g, n));

void double(JSON::YAJL::Generator g, double n)
CODE:
    croak_on_status(yajl_gen_double(g, n));

void number(JSON::YAJL::Generator g, char * n, unsigned int length(n))
CODE:
    croak_on_status(yajl_gen_number(g, n, XSauto_length_of_n));

void string(JSON::YAJL::Generator g, char * s, unsigned int length(s))
CODE:
    croak_on_status(yajl_gen_string(g, (unsigned char*)s, XSauto_length_of_s));

void null(JSON::YAJL::Generator g)
CODE:
    croak_on_status(yajl_gen_null(g));

void bool(JSON::YAJL::Generator g, bool b)
CODE:
    croak_on_status(yajl_gen_bool(g, b));

void map_open(JSON::YAJL::Generator g)
CODE:
    croak_on_status(yajl_gen_map_open(g));

void map_close(JSON::YAJL::Generator g)
CODE:
    croak_on_status(yajl_gen_map_close(g));

void array_open(JSON::YAJL::Generator g)
CODE:
    croak_on_status(yajl_gen_array_open(g));

void array_close(JSON::YAJL::Generator g)
CODE:
    croak_on_status(yajl_gen_array_close(g));

SV* get_buf(JSON::YAJL::Generator g)
CODE:
    const unsigned char* buf;
    size_t len;
    croak_on_status(yajl_gen_get_buf(g, &buf, &len));
    RETVAL = newSVpvn_utf8((char *)buf, (STRLEN)len, 1);
OUTPUT:
    RETVAL

void clear(JSON::YAJL::Generator g)
CODE:
    yajl_gen_clear(g);

void DESTROY(JSON::YAJL::Generator g)
CODE:
    yajl_gen_free(g);
