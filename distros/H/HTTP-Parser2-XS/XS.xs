
#include <parser2.h>

MODULE = HTTP::Parser2::XS		PACKAGE = HTTP::Parser2::XS		


int
parse_http_request(buf, envref)
	SV  *buf
	SV  *envref
    CODE:

	if (!SvROK(envref) || SvTYPE(SvRV(envref)) != SVt_PVHV)
		croak("Second param for parse_http_request must be a hashref");
 
	RETVAL = parse_http_request(buf, envref);
    OUTPUT:
	RETVAL


int
parse_http_response(buf, envref)
	SV  *buf
	SV  *envref
    CODE:

	if (!SvROK(envref) || SvTYPE(SvRV(envref)) != SVt_PVHV)
		croak("Second param for parse_http_response must be a hashref");
 
	RETVAL = parse_http_response(buf, envref);
    OUTPUT:
	RETVAL


int
parse_http_request_psgi(buf, envref)
	SV  *buf
	SV  *envref
    CODE:

	if (!SvROK(envref) || SvTYPE(SvRV(envref)) != SVt_PVHV)
		croak("Second param for parse_http_request must be a hashref");
 
	RETVAL = parse_http_request_psgi(buf, envref);
    OUTPUT:
	RETVAL




