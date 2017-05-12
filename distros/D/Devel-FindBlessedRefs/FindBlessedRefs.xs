#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Devel::FindBlessedRefs PACKAGE = Devel::FindBlessedRefs

PROTOTYPES: DISABLE

void
find_refs(package)
    char *package

    PREINIT:
    SV* sva;
    SV* svend;
    SV* sv;

	PPCODE:
    // this stuff is mostly from perl-5.8.8/sv.c, but cleaned up to look like ordinary XS
    for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
        svend = &sva[SvREFCNT(sva)];

        for (sv = sva + 1; sv < svend; ++sv) {
            if ( SvROK(sv) ) {

                // this part isn't from sv.c
                // int sv_isa(SV* sv, const char* name)
                if( sv_isa(sv, package) )
                    XPUSHs(sv);
            }
        }
    }

void
find_refs_with_coderef(code_ref)
    SV* code_ref;

    PREINIT:
    SV* sva;
    SV* svend;
    SV* sv;
    svtype t;
    U32 c;

	CODE:
    for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
        svend = &sva[SvREFCNT(sva)];

        for (sv = sva + 1; sv < svend; ++sv) {
            if( SvROK(sv) ) {
                dSP; // make a new local stack

                PUSHMARK(SP); // start pushing
                XPUSHs(sv); // push the sv as a mortal
                PUTBACK; // end the stack

                call_sv(code_ref, G_DISCARD);
            }
        }
    }
