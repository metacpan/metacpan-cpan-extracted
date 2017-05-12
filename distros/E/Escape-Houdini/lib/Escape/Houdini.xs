#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <buffer.h>

#define WRAPPER(name)                                          \
	SV *_##name(SV *input){                                    \
	    gh_buf buffer = GH_BUF_INIT;                           \
	    SV *result;                                            \
	    STRLEN slen;                                           \
	    char *src_string;                                      \
	                                                           \
	    if( !SvPOK(input) && !SvNOK(input) && !SvIOK(input) ) {\
	        croak( #name "() argument not a string");            \
	    }                                                      \
	                                                           \
	    src_string = SvPV(input, slen);                        \
	                                                           \
	    if( !houdini_##name( &buffer, src_string, slen ) ) {   \
	        return newSVsv(input);                             \
	    }                                                      \
	                                                           \
	    result = newSVpvn( buffer.ptr, buffer.size );          \
	    gh_buf_free(&buffer);                                  \
	    return result;                                         \
	}

WRAPPER(escape_html)
WRAPPER(unescape_html)
WRAPPER(escape_xml)
WRAPPER(escape_url)
WRAPPER(escape_uri)
WRAPPER(unescape_url)
WRAPPER(unescape_uri)
WRAPPER(escape_js)
WRAPPER(unescape_js)
WRAPPER(escape_href)

MODULE = Escape::Houdini   PACKAGE = Escape::Houdini

SV *
escape_xml(str)
    SV *str;
CODE:
    RETVAL = _escape_xml(str);
OUTPUT:
    RETVAL

SV *
escape_html(str)
    SV *str;
CODE:
    RETVAL = _escape_html(str);
OUTPUT:
    RETVAL

SV *
unescape_html(str)
    SV *str;
CODE:
    RETVAL = _unescape_html(str);
OUTPUT:
    RETVAL

SV *
escape_uri(str)
    SV *str;
CODE:
    RETVAL = _escape_uri(str);
OUTPUT:
    RETVAL

SV *
escape_url(str)
    SV *str;
CODE:
    RETVAL = _escape_url(str);
OUTPUT:
    RETVAL

SV *
escape_href(str)
    SV *str;
CODE:
    RETVAL = _escape_href(str);
OUTPUT:
    RETVAL

SV *
unescape_uri(str)
    SV *str;
CODE:
    RETVAL = _unescape_uri(str);
OUTPUT:
    RETVAL

SV *
unescape_url(str)
    SV *str;
CODE:
    RETVAL = _unescape_url(str);
OUTPUT:
    RETVAL

SV *
escape_js(str)
    SV *str;
CODE:
    RETVAL = _escape_js(str);
OUTPUT:
    RETVAL

SV *
unescape_js(str)
    SV *str;
CODE:
    RETVAL = _unescape_js(str);
OUTPUT:
    RETVAL
