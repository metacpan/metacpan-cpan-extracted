#include "EXTERN.h"
#include "perl.h"

#define DM_SvNEXTMORTAL(sv) ((SvFLAGS(sv) & SVs_TEMP) && DM_scan_for_mortal(sv, FALSE, TRUE))
#define DM_SvMAYBEMORTAL(sv) ((SvFLAGS(sv) & SVs_TEMP) && DM_scan_for_mortal(sv, TRUE, TRUE))

PERL_CALLCONV bool
DM_scan_for_mortal(SV *check_sv, bool from_root, bool to_top);