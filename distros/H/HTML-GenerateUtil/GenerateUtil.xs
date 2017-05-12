#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "GenerateFunctions.h"

#define B_INPLACE 1
#define B_LFTOBR 2
#define B_SPTONBSP 4
#define B_LEAVEKNOWN 8

#define B_ESCAPEVAL 1
#define B_ADDNEWLINE 2
#define B_CLOSETAG 4

MODULE = HTML::GenerateUtil		PACKAGE = HTML::GenerateUtil		

SV *
escape_html(str, ...)
  SV * str
PREINIT:
  int mode = 0;
INIT:
  int b_inplace, b_lftobr, b_sptonbsp, b_leaveknown;
  SV * newstr;

  /* Check it's a string */
  SvGETMAGIC(str);
  if (!SvOK(str)) {
    XSRETURN_UNDEF;
  }
CODE:
  if (items > 1)
    mode = (int)SvIV(ST(1));

  /* Get flags */
  b_inplace = mode & B_INPLACE;
  b_lftobr = mode & B_LFTOBR;
  b_sptonbsp = mode & B_SPTONBSP;
  b_leaveknown = mode & B_LEAVEKNOWN;

  /* Call helper function */
  newstr = GF_escape_html(str, b_inplace, b_lftobr, b_sptonbsp, b_leaveknown);

  if (!newstr)
    XSRETURN_UNDEF;

  /* Increment reference count because RETVAL = does implicit sv_2mortal later */
  if (b_inplace)
    SvREFCNT_inc(newstr);

  RETVAL = newstr;
OUTPUT:
  RETVAL

SV *
generate_attributes(attr)
  SV * attr
INIT:
  SV * attrstr;
  HV * attrhv;

  if (!SvOK(attr) || !SvROK(attr) || SvTYPE(SvRV(attr)) != SVt_PVHV) {
    XSRETURN_UNDEF;
  }

  attrhv = (HV *)SvRV(attr);
CODE:
  attrstr = GF_generate_attributes(attrhv);

  RETVAL = attrstr;
OUTPUT:
  RETVAL

SV *
generate_tag(tag, attr, val, mode)
  SV * tag
  SV * attr
  SV * val
  int mode
INIT:
  SV * tagstr;
  HV * attrhv = 0;
  int b_escapeval, b_addnewline, b_closetag;

  if (!SvOK(tag)) {
    XSRETURN_UNDEF;
  }
  if (SvOK(attr) && (!SvROK(attr) || (SvROK(attr) && SvTYPE(SvRV(attr)) != SVt_PVHV))) {
    XSRETURN_UNDEF;
  }
  if (!SvOK(val)) {
    val = 0;
  }

  attrhv = SvOK(attr) ? (HV *)SvRV(attr) : 0;

  /* Get flags */
  b_escapeval = mode & B_ESCAPEVAL;
  b_addnewline = mode & B_ADDNEWLINE;
  b_closetag = mode & B_CLOSETAG;
CODE:
  tagstr = GF_generate_tag(tag, attrhv, val, b_escapeval, b_addnewline, b_closetag);

  RETVAL = tagstr;
OUTPUT:
  RETVAL

SV *
escape_uri_internal(str, escstr, mode)
  SV * str
  SV * escstr
  int mode
INIT:
  int b_inplace;
  SV * newstr;

  /* Check it's a string */
  SvGETMAGIC(str);
  if (!SvOK(str) || !SvOK(escstr)) {
    XSRETURN_UNDEF;
  }

  /* Get flags */
  b_inplace = mode & B_INPLACE;
CODE:

  /* Call helper function */
  newstr = GF_escape_uri(str, escstr, b_inplace);

  if (!newstr)
    XSRETURN_UNDEF;

  /* Increment reference count because RETVAL = does implicit sv_2mortal later */
  if (b_inplace)
    SvREFCNT_inc(newstr);

  RETVAL = newstr;
OUTPUT:
  RETVAL

void
set_paranoia(paranoia)
  int paranoia
INIT:

  /* Call helper function */
  GF_set_paranoia(paranoia);

  XSRETURN_UNDEF;

