#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = Devel::Gladiator		PACKAGE = Devel::Gladiator



SV*
walk_arena()
PPCODE:
{
  SV* sva;
  I32 visited = 0;
  AV* av = newAV();
  for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
    register const SV * const svend = &sva[SvREFCNT(sva)];
    SV* svi;
    for (svi = sva + 1; svi < svend; ++svi) {
      if (SvTYPE(svi) != SVTYPEMASK
          && SvREFCNT(svi)
          && svi != (SV*)av
          )
        {
          /** skip pads, they have a PVAV as their first element inside a PVAV **/
          if (SvTYPE(svi) == SVt_PVAV &&
              av_len( (AV*) svi) != -1) {
            SV** first = AvARRAY((AV*)svi);
            if (first && *first && SvTYPE(*first) == SVt_PVAV) {
              continue;
            }
            if (first && *first && SvTYPE(*first) == SVt_PVCV) {
              continue;
            }
          }
          if (SvTYPE(svi) == SVt_PVCV && CvROOT((CV*)svi) == 0) {
            continue;
          }
          ++visited;
          av_push(av,svi);
          SvREFCNT_inc(svi);
        }
    }
  }

  while (visited--) {
    SV** sv = av_fetch(av, visited, (I32)0);

    /**    if (SvTYPE(sv) == SVt_PV
        || SvTYPE(sv) == SVt_IV
        || SvTYPE(sv) == SVt_NV
        || SvTYPE(sv) == SVt_RV
        || SvTYPE(sv) == SVt_PVIV
        || SvTYPE(sv) == SVt_PVNV
        || SvTYPE(sv) == SVt_PVMG) {
    **/
    if(sv) {
      av_store(av, visited, newRV_inc(*sv));
    }
  }

  ST(0) = newRV_noinc((SV*)av);
  sv_2mortal(ST(0));

  /*sv_dump(ST(0)); */
  XSRETURN(1);
}

