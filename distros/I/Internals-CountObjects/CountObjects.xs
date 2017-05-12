#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static const char* const svclassnames[] = {
    "undef",
#if PERL_VERSION >= 9
    "B::BIND",
#endif
    "integer",
    "double",
    "REF",
    "string",
    "string/integer",
    "string/double",
    "scalar + misc magic",
#if PERL_VERSION <= 8
    "SCALAR: BM",
#endif
#if PERL_VERSION >= 9
    "GLOB",
#endif
    "LVALUE",
    "ARRAY",
    "HASH",
    "CODE",
#if PERL_VERSION <= 8
    "GLOB",
#endif
    "FORMAT",
    "IO::Handle",
};

MODULE = Internals::CountObjects       PACKAGE = Internals::CountObjects

HV*
objects()
    PREINIT:
        SV *sva, *sv, *svend;
        char *reftype;
    CODE:
        RETVAL = newHV();
        for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
            svend = &sva[SvREFCNT(sva)];
            for (sv = sva + 1; sv < svend; ++sv) {
                if (SvTYPE(sv) == SVTYPEMASK) {
                    reftype = "undef";
                }
                else {
                    reftype  = sv_reftype(sv, 1);
                    if (strEQ(reftype, "SCALAR")) {
                        reftype = svclassnames[SvTYPE(sv)];
                    }
                }
                sv_inc(*hv_fetch(RETVAL, reftype, strlen(reftype), 1));
            }
        }
    OUTPUT:
        RETVAL
