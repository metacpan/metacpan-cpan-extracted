#include "lib/xshelper.h"

#define dcAllocMem Newxz
#define dcFreeMem  Safefree

// Based on https://github.com/svn2github/dyncall/blob/master/bindings/ruby/rbdc/rbdc.c

#include <dynload.h>
#include <dyncall.h>
#include <dyncall_value.h>
#include <dyncall_callf.h>
#include <dyncall_signature.h>
#include <dyncall_callback.h>

#include "lib/types.h"

MODULE = Dyn::Call   PACKAGE = Dyn::Call

DCCallVM *
dcNewCallVM(DCsize size);

void
dcFree(DCCallVM * vm);
CODE:
    dcFree(vm);
    SV* sv = (SV*) &PL_sv_undef;
    sv_setsv(ST(0), sv);

void
dcMode(DCCallVM * vm, DCint mode);

void
dcReset(DCCallVM * vm);

void
dcArgBool(DCCallVM * vm, DCbool arg);

void
dcArgChar(DCCallVM * vm, DCchar arg);

void
dcArgShort(DCCallVM * vm, DCshort arg);

void
dcArgInt(DCCallVM * vm, DCint arg);

void
dcArgLong(DCCallVM * vm, DClong arg);

void
dcArgLongLong(DCCallVM * vm, DClonglong arg);

void
dcArgFloat(DCCallVM * vm, DCfloat arg);

void
dcArgDouble(DCCallVM * vm, DCdouble arg);

void
dcArgPointer(DCCallVM * vm, arg);
CODE:
    if (sv_derived_from(ST(1), "Dyn::Callback") ) {
        IV tmp = SvIV((SV*)SvRV(ST(1)));
        DCCallback * arg = INT2PTR(DCCallback *, tmp);
        dcArgPointer(vm, arg);
    }
    else if (sv_derived_from(ST(1), "Dyn::pointer")){
        IV tmp = SvIV((SV*)SvRV(ST(1)));
        DCpointer arg = INT2PTR(DCpointer, tmp);
        dcArgPointer(vm, arg);
    }
    else
        croak("arg is not of type Dyn::pointer");

void
dcArgStruct(DCCallVM * vm, DCstruct * s, DCpointer value);

=pod

=for This is not part of dyncall's API

=cut

void
dcArgString(DCCallVM * vm, char * arg);
CODE:
    dcArgPointer(vm, arg);

void
dcCallVoid(DCCallVM * vm, DCpointer funcptr);

DCbool
dcCallBool(DCCallVM * vm, DCpointer funcptr);

DCchar
dcCallChar(DCCallVM * vm, DCpointer funcptr);

DCshort
dcCallShort(DCCallVM * vm, DCpointer funcptr);

DCint
dcCallInt(DCCallVM * vm, DCpointer funcptr);

DClong
dcCallLong(DCCallVM * vm, DCpointer funcptr);

DClonglong
dcCallLongLong(DCCallVM * vm, DCpointer funcptr);

DCfloat
dcCallFloat(DCCallVM * vm, DCpointer funcptr);

DCdouble
dcCallDouble(DCCallVM * vm, DCpointer funcptr);

DCpointer
dcCallPointer(DCCallVM * vm, DCpointer funcptr);

const char *
dcCallString(DCCallVM * vm, DCpointer funcptr);
CODE:
    RETVAL = dcCallPointer(vm, funcptr);
OUTPUT:
    RETVAL

=todo

void
dcArgF(DCCallVM * vm, const DCsigchar * signature, ...);

void
dcVArgF(DCCallVM * vm, const DCsigchar * signature, va_list args);

=cut

void
dcCallF(DCCallVM * vm, DCValue * result, DCpointer funcptr, const DCsigchar * signature);
OUTPUT:
    result

=todo

dcCallF(DCCallVM * vm, DCValue * result, DCpointer funcptr, const DCsigchar * signature, ...);

void
dcVCallF(DCCallVM * vm, DCValue * result, DCpointer funcptr, const DCsigchar * signature, va_list args);

=cut

DCint
dcGetError(DCCallVM* vm);

BOOT:
{
    HV *stash = gv_stashpv("Dyn::Call", 0);

    // Supported Calling Convention Modes
    newCONSTSUB(stash, "DC_CALL_C_DEFAULT", newSViv(DC_CALL_C_DEFAULT));
    newCONSTSUB(stash, "DC_CALL_C_ELLIPSIS", newSViv(DC_CALL_C_ELLIPSIS));
    newCONSTSUB(stash, "DC_CALL_C_ELLIPSIS_VARARGS", newSViv(DC_CALL_C_ELLIPSIS_VARARGS));
    newCONSTSUB(stash, "DC_CALL_C_X86_CDECL", newSViv(DC_CALL_C_X86_CDECL));
    newCONSTSUB(stash, "DC_CALL_C_X86_WIN32_STD", newSViv(DC_CALL_C_X86_WIN32_STD));
    newCONSTSUB(stash, "DC_CALL_C_X86_WIN32_FAST_MS", newSViv(DC_CALL_C_X86_WIN32_FAST_MS));
    newCONSTSUB(stash, "DC_CALL_C_X86_WIN32_FAST_GNU", newSViv(DC_CALL_C_X86_WIN32_FAST_GNU));
    newCONSTSUB(stash, "DC_CALL_C_X86_WIN32_THIS_MS", newSViv(DC_CALL_C_X86_WIN32_THIS_MS));
    newCONSTSUB(stash, "DC_CALL_C_X86_WIN32_THIS_GNU", newSViv(DC_CALL_C_X86_WIN32_THIS_GNU));
    newCONSTSUB(stash, "DC_CALL_C_X64_WIN64", newSViv(DC_CALL_C_X64_WIN64));
    newCONSTSUB(stash, "DC_CALL_C_X64_SYSV", newSViv(DC_CALL_C_X64_SYSV));
    newCONSTSUB(stash, "DC_CALL_C_PPC32_DARWIN", newSViv(DC_CALL_C_PPC32_DARWIN));
    newCONSTSUB(stash, "DC_CALL_C_PPC32_OSX", newSViv(DC_CALL_C_PPC32_OSX));
    newCONSTSUB(stash, "DC_CALL_C_ARM_ARM_EABI", newSViv(DC_CALL_C_ARM_ARM_EABI));
    newCONSTSUB(stash, "DC_CALL_C_ARM_THUMB_EABI", newSViv(DC_CALL_C_ARM_THUMB_EABI));
    newCONSTSUB(stash, "DC_CALL_C_ARM_ARMHF", newSViv(DC_CALL_C_ARM_ARMHF));
    newCONSTSUB(stash, "DC_CALL_C_MIPS32_EABI", newSViv(DC_CALL_C_MIPS32_EABI));
    newCONSTSUB(stash, "DC_CALL_C_MIPS32_PSPSDK", newSViv(DC_CALL_C_MIPS32_PSPSDK));
    newCONSTSUB(stash, "DC_CALL_C_PPC32_SYSV", newSViv(DC_CALL_C_PPC32_SYSV));
    newCONSTSUB(stash, "DC_CALL_C_PPC32_LINUX", newSViv(DC_CALL_C_PPC32_LINUX));
    newCONSTSUB(stash, "DC_CALL_C_ARM_ARM", newSViv(DC_CALL_C_ARM_ARM));
    newCONSTSUB(stash, "DC_CALL_C_ARM_THUMB", newSViv(DC_CALL_C_ARM_THUMB));
    newCONSTSUB(stash, "DC_CALL_C_MIPS32_O32", newSViv(DC_CALL_C_MIPS32_O32));
    newCONSTSUB(stash, "DC_CALL_C_MIPS64_N32", newSViv(DC_CALL_C_MIPS64_N32));
    newCONSTSUB(stash, "DC_CALL_C_MIPS64_N64", newSViv(DC_CALL_C_MIPS64_N64));
    newCONSTSUB(stash, "DC_CALL_C_X86_PLAN9", newSViv(DC_CALL_C_X86_PLAN9));
    newCONSTSUB(stash, "DC_CALL_C_SPARC32", newSViv(DC_CALL_C_SPARC32));
    newCONSTSUB(stash, "DC_CALL_C_SPARC64", newSViv(DC_CALL_C_SPARC64));
    newCONSTSUB(stash, "DC_CALL_C_ARM64", newSViv(DC_CALL_C_ARM64));
    newCONSTSUB(stash, "DC_CALL_C_PPC64", newSViv(DC_CALL_C_PPC64));
    newCONSTSUB(stash, "DC_CALL_C_PPC64_LINUX", newSViv(DC_CALL_C_PPC64_LINUX));
    newCONSTSUB(stash, "DC_CALL_SYS_DEFAULT", newSViv(DC_CALL_SYS_DEFAULT));
    newCONSTSUB(stash, "DC_CALL_SYS_X86_INT80H_LINUX", newSViv(DC_CALL_SYS_X86_INT80H_LINUX));
    newCONSTSUB(stash, "DC_CALL_SYS_X86_INT80H_BSD", newSViv(DC_CALL_SYS_X86_INT80H_BSD));
    newCONSTSUB(stash, "DC_CALL_SYS_PPC32", newSViv(DC_CALL_SYS_PPC32));
    newCONSTSUB(stash, "DC_CALL_SYS_PPC64", newSViv(DC_CALL_SYS_PPC64));

    // Error codes
    newCONSTSUB(stash, "DC_ERROR_NONE", newSViv(DC_ERROR_NONE));
    newCONSTSUB(stash, "DC_ERROR_UNSUPPORTED_MODE", newSViv(DC_ERROR_UNSUPPORTED_MODE));
}