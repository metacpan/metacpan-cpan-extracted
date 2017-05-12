#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define __EMBEDDED_MODULE__
#include "twepl_xcore.c"
#undef __EMBEDDED_MODULE__

MODULE = HTML::EmbeddedPerl PACKAGE = HTML::EmbeddedPerl

BOOT:
  /* Register Section */
  twepl_register(aTHX_ file);

SV* ep(...)

  INIT:

    int idx = twepl_check_caller(aTHX_ ST(0), items, 1, "ep", "$code");
    if(idx == -1){
      ST(0) = Nullsv; XSRETURN(1);
    }

      char *epc = SvPV_nolen(ST(idx));

  CODE:

    enum TWEPL_STATE  ret;
                char *cnv = NULL;
                  SV *buf;
                  SV *opt;

    /* Buffer */
    buf = perl_get_sv(EPL_PM_NAME "::STOBUF", FALSE);
    /* Options */
    opt = perl_get_sv(EPL_PM_NAME "::EPLOPT", FALSE);

    /* PerlIO_stdout -> PerlIO::Scalar */
    if(! twepl_do_open(aTHX_ EPL_PM_NAME "::STOTMP", "STDOUT", EPL_FOM, EPL_PM_NAME "::STOBUF", EPL_FOF)){
      Perl_croak(aTHX_ "ep: failed override stdhandle.");
    }

    /* Convert */
    ret = twepl_code(epc, &cnv, SvIV(opt));

    if(ret != TWEPL_OKEY_NOERR){
      free(cnv);
      twepl_do_close(aTHX_ "STDOUT");
      Perl_croak(aTHX_ "ep: %s", twepl_strerr(ret));
    }

    /* Run */
    eval_pv((const char *)cnv, G_EVAL|G_KEEPERR|G_DISCARD);

    /* Clean-Ups */
    free(cnv);

    if(SvTRUE(ERRSV)){
      twepl_do_close(aTHX_ "STDOUT");
      Perl_croak(aTHX_ "%s", SvPV_nolen(ERRSV));
    }

    /* Return Value */
    RETVAL = newSVpv(SvPV_nolen(buf), 0);

    /* PerlIO_stdout <- PerlIO::Scalar */
    twepl_do_close(aTHX_ "STDOUT");

    /* wantarray? */
    if(GIMME_V == G_VOID){
      PerlIO_puts(PerlIO_stdout(), (char *)RETVAL);
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL

SV*
_twepl_handler(...)

  INIT:

    int idx = twepl_check_caller(aTHX_ ST(0), items, 1, "_twepl_handler", "$code");
    if(idx == -1){
      ST(0) = Nullsv; XSRETURN(1);
    }

      char *fin = SvPV_nolen(ST(idx));
        SV *bks = perl_get_sv(EPL_PM_NAME "::STOTMP", FALSE);
    PerlIO *bki = (PerlIO*)(long)SvIV(bks);

  CODE:

    enum TWEPL_STATE  ret;
                char *cnv = NULL;
                  SV *buf;
                  SV *opt;

    /* Buffer */
    buf = perl_get_sv(EPL_PM_NAME "::STOBUF", FALSE);
    /* Options */
    opt = perl_get_sv(EPL_PM_NAME "::EPLOPT", FALSE);

    /* PerlIO_stdout -> PerlIO::Scalar */
    if(! twepl_do_open(aTHX_ EPL_PM_NAME "::STOTMP", "STDOUT", EPL_FOM, EPL_PM_NAME "::STOBUF", EPL_FOF)){
      Perl_croak(aTHX_ "_twepl_handler: failed override stdhandle.");
    }

    /* Convert */
    ret = twepl_file(fin, &cnv, SvIV(opt));

    if(ret != TWEPL_OKEY_NOERR){
      free(cnv);
      twepl_do_close(aTHX_ "STDOUT");
      Perl_croak(aTHX_ "twepl_handler: %s", twepl_strerr(ret));
    }

    /* Run */
    eval_pv((const char *)cnv, G_EVAL|G_KEEPERR|G_DISCARD);

    /* Clean-Ups */
    free(cnv);

    if(SvTRUE(ERRSV)){
      twepl_do_close(aTHX_ "STDOUT");
      Perl_croak(aTHX_ "%s", SvPV_nolen(ERRSV));
    }

    /* Return Value */
    RETVAL = newSVpv(SvPV_nolen(buf), 0);

    /* PerlIO_stdout <- PerlIO::Scalar */
    twepl_do_close(aTHX_ "STDOUT");

    /* wantarray? */
    if(GIMME_V == G_VOID){
      PerlIO_puts(PerlIO_stdout(), (char *)RETVAL);
      RETVAL = Nullsv;
    }

  OUTPUT:
    RETVAL
