#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define HAVE_PERL(R, V, S) (           \
    PERL_REVISION > (R) || (           \
        PERL_REVISION == (R) && (      \
            PERL_VERSION > (V) || (    \
                PERL_VERSION == (V) && \
                PERL_SUBVERSION >= (S) \
            )                          \
        )                              \
    )                                  \
)


MODULE = Devel::ChangePackage  PACKAGE = Devel::ChangePackage

SV *
change_package (package)
    SV *package
  CODE:
    RETVAL = newSVsv(PL_curstname);
#if HAVE_PERL(5, 15, 5)
    SvREFCNT_dec(PL_curstash);
    PL_curstash = (HV *)SvREFCNT_inc(gv_stashsv(package, GV_ADD));
#else
    PL_curstash = gv_stashsv(package, GV_ADD);
#endif
    sv_setsv(PL_curstname, package);
  OUTPUT:
    RETVAL
