#include "EXTERN.h"
#include "perl.h"
#include "embed.h"

#include "XSUB.h"
//#include "defsubs.h"
#define NEED_sv_2pv_flags
#include "ppport.h"
#include "opcode.h"

MODULE = Debug::Flags                PACKAGE = Debug::Flags

PROTOTYPES: DISABLE

BOOT:
{
    HV *stash = gv_stashpvn("Debug::Flags", 1, TRUE);
    AV *export_ok = perl_get_av("B::EXPORT_OK",TRUE);
#include "defsubs.h"
}

I32
get_flags()
CODE:
       RETVAL = PL_debug;
    OUTPUT:
       RETVAL    

void
set_flags(flags)
    I32 flags
CODE: 
    PL_debug = flags;

