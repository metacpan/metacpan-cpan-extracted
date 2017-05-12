#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "Devel_Mortality.h"

bool
DM_scan_for_mortal(SV *check_sv, bool from_root, bool to_top) {
    I32 ix = from_root ? 0 : PL_tmps_floor + 1;
    I32 top = to_top || !from_root ? PL_tmps_ix + 1 : PL_tmps_floor;
    while(ix < top) {
        if (PL_tmps_stack[ix] == check_sv) {
            return 1;
        }
        ix++;
    }
    
    return 0;
}

MODULE = Devel::Mortality		PACKAGE = Devel::Mortality

void
__test()
  PREINIT:
    SV *sv1, *sv2;
    char *nok[] = {"0", NULL};
    char *ok[] = {"1", NULL};
  CODE: 
  {
    SAVETMPS;

    sv1 = newSViv(0);
    /* Should not be temp */
    call_argv("main::ok", G_DISCARD, (!DM_SvNEXTMORTAL(sv1) ? ok : nok));
    
    sv_2mortal(sv1);
    call_argv("main::ok", G_DISCARD, (DM_SvNEXTMORTAL(sv1) ? ok : nok));

    {
        SAVETMPS;
        sv2 = sv_newmortal();
        call_argv("main::ok", G_DISCARD, (!DM_SvNEXTMORTAL(sv1) ? ok : nok));
        call_argv("main::ok", G_DISCARD, (DM_SvNEXTMORTAL(sv2) ? ok : nok));
        call_argv("main::ok", G_DISCARD, (DM_SvMAYBEMORTAL(sv1) ? ok : nok));
        call_argv("main::ok", G_DISCARD, (DM_SvMAYBEMORTAL(sv2) ? ok : nok));
        FREETMPS;
    }
    
    FREETMPS;
    call_argv("main::ok", G_DISCARD, (!DM_SvNEXTMORTAL(sv1) ? ok : nok));
  }

    