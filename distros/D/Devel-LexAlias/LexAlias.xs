#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PadARRAY
typedef AV PADNAMELIST;
typedef SV PADNAME;
# if PERL_VERSION < 8 || (PERL_VERSION == 8 && !PERL_SUBVERSION)
typedef AV PAD;
# endif
# define PadlistARRAY(pl)      ((PAD **)AvARRAY(pl))
# define PadlistNAMES(pl)      (*PadlistARRAY(pl))
# define PadnamelistARRAY(pnl) ((PADNAME **)AvARRAY(pnl))
# define PadnamelistMAX(pnl)   AvFILLp(pnl)
# define PadARRAY              AvARRAY
# define PadnamePV(pn)         (SvPOKp(pn) ? SvPVX(pn) : NULL)
#endif



/* cargo-culted from PadWalker */

MODULE = Devel::LexAlias                PACKAGE = Devel::LexAlias

void
_lexalias(SV* cv_ref, char *name, SV* new_rv)
  CODE:
{
    CV*          cv   = SvROK(cv_ref) ? (CV*) SvRV(cv_ref) : NULL;
    PADNAMELIST* padn = cv ? PadlistNAMES(CvPADLIST(cv)) : PL_comppad_name;
    PAD*         padv = cv ? PadlistARRAY(CvPADLIST(cv))[1] : PL_comppad;
    SV*          new_sv;
    I32          i;

    if (!SvROK(new_rv)) croak("ref is not a reference");
    new_sv = SvRV(new_rv);

    for (i = 0; i <= PadnamelistMAX(padn); ++i) {
        PADNAME* namesv = PadnamelistARRAY(padn)[i];
        char*    name_str;
        if (namesv && (name_str = PadnamePV(namesv))) {
            if (!strcmp(name, name_str)) {
                SvREFCNT_dec(PadARRAY(padv)[i]);
                PadARRAY(padv)[i] = new_sv;
                SvREFCNT_inc(new_sv);
                SvPADMY_on(new_sv);
            }
        }
    }
}
