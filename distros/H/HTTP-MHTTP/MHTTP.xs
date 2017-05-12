#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "mhttp.h"


void my_http_reset( ) {

  mhttp_reset();

}

void my_http_init( ) {

  mhttp_init();

}

void my_http_set_protocol(SV* sv_proto) {

  mhttp_set_protocol(SvIV(sv_proto));

}

void my_switch_debug(SV* sv_swt) {

  mhttp_switch_debug(SvIV(sv_swt));

}

void my_add_header(SV* sv_hdr) {

  mhttp_add_header(SvPV(sv_hdr,SvCUR(sv_hdr)));

}

SV* my_http_headers( ) {

  return newSVpv(mhttp_get_response_headers(),0);

}

void my_http_body(SV* sv_bdy) {

  mhttp_set_body(
     SvPV(sv_bdy,SvCUR(sv_bdy))
     );

}

SV* my_http_reason( ) {

  char* reason;

  reason = mhttp_get_reason();

  if (reason != NULL){
       return newSVpv(reason,0);
  } else {
       return newSVsv(&PL_sv_undef);
  }

}

SV* my_http_response( ) {

  if (mhttp_get_response_length() > 0){
      return newSVpv(mhttp_get_response(),mhttp_get_response_length());
  } else {
       return newSVsv(&PL_sv_undef);
  }

}

SV* my_http_status( ) {

  return newSViv(mhttp_get_status_code());

}

SV* my_http_response_length( ) {

  return newSViv(mhttp_get_response_length());

}

SV* my_http_call(SV* sv_action, SV* sv_url) {

  return newSViv(
      mhttp_call(
           SvPV(sv_action,SvCUR(sv_action)),
	   SvPV(sv_url,SvCUR(sv_url))
	   )
         );

}


MODULE = HTTP::MHTTP	PACKAGE = HTTP::MHTTP	PREFIX = my_

PROTOTYPES: DISABLE

void
my_http_reset ( )

void
my_http_init ( )

void
my_http_set_protocol (sv_proto)
	SV *	sv_proto

void
my_switch_debug (sv_swt)
	SV *	sv_swt

void
my_add_header (sv_hdr)
	SV *	sv_hdr

SV*
my_http_headers ( )

void
my_http_body (sv_bdy)
	SV *	sv_bdy

SV*
my_http_reason ( )

SV*
my_http_response ( )

SV*
my_http_status ( )

SV*
my_http_response_length ( )

SV*
my_http_call (sv_action, sv_url)
	SV *	sv_action
	SV *	sv_url

