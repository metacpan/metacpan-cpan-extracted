#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* this is borrowed/modified from Devel::LexAlias */

MODULE = Lexical::Alias			PACKAGE = Lexical::Alias

void
alias_r (src, dst)
	SV *src
	SV *dst
  CODE:
  {
    AV* padv = PL_comppad;
    int dt, st;
    I32 i;

    if (!SvROK(src) || !SvROK(dst))
      croak("destination and source must be references");

    /* allow people to say alias(dst => src) instead */
    if (SvIV(perl_get_sv("Lexical::Alias::SWAP", FALSE)) == 1) {
      SV *tmp = src;
      src = dst;
      dst = tmp;
    }

    dt = SvTYPE(SvRV(dst));
    st = SvTYPE(SvRV(src));

    if (!(dt < SVt_PVAV && st < SVt_PVAV || dt == st && dt <= SVt_PVHV))
      croak("destination and source must be same type (%d != %d)",dt,st);

    for (i = 0; i <= av_len(padv); ++i) {
      SV** myvar_ptr = av_fetch(padv, i, 0);
      if (myvar_ptr) {
        if (SvRV(dst) == *myvar_ptr) {
          av_store(padv, i, SvRV(src));
          SvREFCNT_inc(SvRV(src));
        }
      }
    }
  }
