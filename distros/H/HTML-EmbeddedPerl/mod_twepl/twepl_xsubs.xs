#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "twepl_parse.c"

MODULE = HTML::EmbeddedPerl PACKAGE = HTML::EmbeddedPerl

int
header_out(...)
  INIT:
    int idx = twepl_check_caller(aTHX_ ST(0), items, 2, "header_out", "$key, $value");
    if(idx == -1){
      RETVAL = idx; XSprePUSH; PUSHi((IV)RETVAL); XSRETURN(1);
    }
    char *key   = SvPV_nolen(ST(idx));
    char *value = SvPV_nolen(ST(idx+1));
  CODE:
      HV *hdr = perl_get_hv(EPL_PM_NAME "::HEADER", FALSE);

    /* Content-Type */
    if(strcasecmp(key, "Content-Type") == 0){
      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSVpv(value, 0)));
      PUTBACK;
      call_pv(EPL_PM_NAME "::content_type", G_SCALAR|G_KEEPERR);
      SPAGAIN;
      PUTBACK;
      RETVAL = POPi;
      FREETMPS;
      LEAVE;
    } else{
      if(hv_exists(hdr, key, strlen(key)) && *value == '\0'){
        hv_delete(hdr, key, strlen(key), FALSE);
        RETVAL = EPL_XS_FLAG_DEL;
      } else{
        hv_store(hdr, key, strlen(key), newSVpv(value, 0), 0);
        RETVAL = TRUE;
      }
    }
  OUTPUT:
    RETVAL

int
header(...)
  INIT:
    int idx = twepl_check_caller(aTHX_ ST(0), items, 1, "header", "\x22$key: $value\x22");
    if(idx == -1){
      RETVAL = idx; XSprePUSH; PUSHi((IV)RETVAL); XSRETURN(1);
    }
    char *header_pair = SvPV_nolen(ST(idx));
  CODE:
      HV *hdr = perl_get_hv(EPL_PM_NAME "::HEADER", FALSE);
      SV *key;
      SV *val;
    char *pos;
    if((pos = strstr(header_pair, HEAD_DM)) != NULL){
      key = newSVpv(header_pair, ((long)pos - (long)header_pair));
      val = newSVpv(pos+2, (strlen(pos) - 2));
      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(sv_2mortal(key));
      XPUSHs(sv_2mortal(val));
      PUTBACK;
      call_pv(EPL_PM_NAME "::header_out", G_SCALAR|G_KEEPERR);
      SPAGAIN;
      PUTBACK;
      RETVAL = POPi;
      FREETMPS;
      LEAVE;
    } else{
      Perl_warn(aTHX_ "Usage: %s(%s)", "twepl::header", "\x22$key: $value\x22");
      RETVAL = FALSE;
    }
  OUTPUT:
    RETVAL

int
content_type(...)
  INIT:
    int idx = twepl_check_caller(aTHX_ ST(0), items, 1, "content_type", "$type_string");
    if(idx == -1){
      RETVAL = idx; XSprePUSH; PUSHi((IV)RETVAL); XSRETURN(1);
    }
    char *contype = SvPV_nolen(ST(idx));
  CODE:
      SV *ctt = perl_get_sv(EPL_PM_NAME "::CONTYP", FALSE);
    if(*contype == '\0'){
      sv_setpv(ctt, EPL_CONTYPE);
      RETVAL = EPL_XS_FLAG_RES;
    } else{
      sv_setpv(ctt, contype);
      RETVAL = TRUE;
    }
  OUTPUT:
    RETVAL

void
echo(...)
  INIT:
        SV *bak = perl_get_sv(EPL_PM_NAME "::STOTMP", FALSE);
    PerlIO *tmp = (PerlIO*)(long)SvIV(bak);
  CODE:
    PerlIO_puts(tmp, SvPV_nolen(sv_isobject(ST(0))? ST(1) : ST(0)));

SV*
new(...)
  INIT:
    char *classname = (sv_isobject(ST(0)))? HvNAME(SvSTASH(SvRV(ST(0)))) : SvPV_nolen(ST(0));
    SV *obj = (SV*)newSV(0);
    SV *ref = newRV_noinc(obj);
  CODE:
    sv_bless(ref, gv_stashpv(classname, FALSE));
    RETVAL = ref;
  OUTPUT:
    RETVAL

SV*
get_file(...)
  INIT:
    int idx = twepl_check_caller(aTHX_ ST(0), items, 1, "get_file", "$file_path");
    if(idx == -1){
      ST(0) = Nullsv; XSRETURN(1);
    }
    char *gfp = SvPV_nolen(ST(idx));
  CODE:
    enum TWEPL_STATE ret;
      SV *opt = perl_get_sv(EPL_PM_NAME "::EPLOPT", FALSE);
    char *cnv = NULL;
    ret = twepl_file(gfp , &cnv, (int)SvIV(opt));
    if(ret != TWEPL_OKEY_NOERR){
      Perl_warn(aTHX_ "get_file: %s", twepl_strerr(ret));
      RETVAL = Nullsv;
    } else{
      RETVAL= newSVpv(cnv, 0);
      free(cnv);
    }
  OUTPUT:
    RETVAL

SV*
get_code(...)
  INIT:
    int idx = twepl_check_caller(aTHX_ ST(0), items, 1, "get_code", "$code");
    if(idx == -1){
      ST(0) = Nullsv; XSRETURN(1);
    }
    char *epc = SvPV_nolen(ST(idx));
  CODE:
    enum TWEPL_STATE ret;
      SV *opt = perl_get_sv(EPL_PM_NAME "::EPLOPT", FALSE);
    char *cnv = NULL;
    ret = twepl_code(epc , &cnv, (int)SvIV(opt));
    if(ret != TWEPL_OKEY_NOERR){
      Perl_warn(aTHX_ "get_code: %s", twepl_strerr(ret));
      RETVAL = Nullsv;
    } else{
      RETVAL= newSVpv(cnv, 0);
      free(cnv);
    }
  OUTPUT:
    RETVAL

int
run_file(...)
  INIT:
    int idx = twepl_check_caller(aTHX_ ST(0), items, 1, "run_file", "$file_path");
    if(idx == -1){
      RETVAL = idx; XSprePUSH; PUSHi((IV)RETVAL); XSRETURN(1);
    }
    char *gfp = SvPV_nolen(ST(idx));
  CODE:
    enum TWEPL_STATE ret;
      SV *opt = perl_get_sv(EPL_PM_NAME "::EPLOPT", FALSE);
    char *cnv = NULL;
    ret = twepl_file(gfp , &cnv, (int)SvIV(opt));
    if(ret != TWEPL_OKEY_NOERR){
      Perl_warn(aTHX_ "run_file: %s", twepl_strerr(ret));
      RETVAL = FALSE;
    } else{
      eval_pv((const char*)cnv, G_EVAL|G_KEEPERR|G_DISCARD);
      free(cnv);
      RETVAL = TRUE;
    }
  OUTPUT:
    RETVAL

int
run_code(...)
  INIT:
    int idx = twepl_check_caller(aTHX_ ST(0), items, 1, "run_code", "$code");
    if(idx == -1){
      RETVAL = idx; XSprePUSH; PUSHi((IV)RETVAL); XSRETURN(1);
    }
    char *epc = SvPV_nolen(ST(idx));
  CODE:
    enum TWEPL_STATE ret;
      SV *opt = perl_get_sv(EPL_PM_NAME "::EPLOPT", FALSE);
    char *cnv = NULL;
    ret = twepl_code(epc , &cnv, (int)SvIV(opt));
    if(ret != TWEPL_OKEY_NOERR){
      Perl_warn(aTHX_ "run_code: %s", twepl_strerr(ret));
      RETVAL = FALSE;
    } else{
      eval_pv((const char*)cnv, G_EVAL|G_KEEPERR|G_DISCARD);
      free(cnv);
      RETVAL = TRUE;
    }
  OUTPUT:
    RETVAL
