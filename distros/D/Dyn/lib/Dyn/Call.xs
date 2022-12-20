#include "lib/clutter.h"

// clang-format off

MODULE = Dyn::Call   PACKAGE = Dyn::Call

DCCallVM *
dcNewCallVM(DCsize size);

void
dcFree(DCCallVM * vm)
CODE:
    // clang-format on
    dcFree(vm);
SV *sv = (SV *)&PL_sv_undef;
sv_setsv(ST(0), sv);
// clang-format off

void
dcReset(DCCallVM * vm);

void
dcMode(DCCallVM * vm, DCint mode);

void
dcBeginCallAggr(DCCallVM * vm, DCaggr * ag);

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
    // clang-format on
    if (sv_derived_from(ST(1), "Dyn::Callback")) {
    IV tmp = SvIV((SV *)SvRV(ST(1)));
    DCCallback *arg = INT2PTR(DCCallback *, tmp);
    dcArgPointer(vm, arg);
}
else if (sv_derived_from(ST(1), "Dyn::Call::Pointer")) {
    IV tmp = SvIV((SV *)SvRV(ST(1)));
    DCpointer arg = INT2PTR(DCpointer, tmp);
    dcArgPointer(vm, arg);
}
else croak("arg is not of type Dyn::Call::Pointer or Dyn::Callback");
// clang-format off

void
dcArgAggr(DCCallVM * vm, DCaggr * s, DCpointer value);

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

DCpointer
dcCallAggr(DCCallVM* vm, DCpointer funcptr, DCaggr* ag, DCpointer ret);

const char *
dcCallString(DCCallVM * vm, DCpointer funcptr);
CODE:
    RETVAL = (const char *) dcCallPointer(vm, funcptr);
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
// clang-format on
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

    // Signature characters
    newCONSTSUB(stash, "DC_SIGCHAR_VOID", newSVpv(form("%c", DC_SIGCHAR_VOID), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_BOOL", newSVpv(form("%c", DC_SIGCHAR_BOOL), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CHAR", newSVpv(form("%c", DC_SIGCHAR_CHAR), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_UCHAR", newSVpv(form("%c", DC_SIGCHAR_UCHAR), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_SHORT", newSVpv(form("%c", DC_SIGCHAR_SHORT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_USHORT", newSVpv(form("%c", DC_SIGCHAR_USHORT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_INT", newSVpv(form("%c", DC_SIGCHAR_INT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_UINT", newSVpv(form("%c", DC_SIGCHAR_UINT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_LONG", newSVpv(form("%c", DC_SIGCHAR_LONG), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_ULONG", newSVpv(form("%c", DC_SIGCHAR_ULONG), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_LONGLONG", newSVpv(form("%c", DC_SIGCHAR_LONGLONG), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_ULONGLONG", newSVpv(form("%c", DC_SIGCHAR_ULONGLONG), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_FLOAT", newSVpv(form("%c", DC_SIGCHAR_FLOAT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_DOUBLE", newSVpv(form("%c", DC_SIGCHAR_DOUBLE), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_POINTER", newSVpv(form("%c", DC_SIGCHAR_POINTER), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_STRING",
                newSVpv(form("%c", DC_SIGCHAR_STRING),
                        1)); /* in theory same as 'p', but convenient to disambiguate */
    newCONSTSUB(stash, "DC_SIGCHAR_AGGREGATE", newSVpv(form("%c", DC_SIGCHAR_AGGREGATE), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_ENDARG",
                newSVpv(form("%c", DC_SIGCHAR_ENDARG), 1)); /* also works for end struct */

    /* calling convention / mode signatures */
    newCONSTSUB(stash, "DC_SIGCHAR_CC_PREFIX", newSVpv(form("%c", DC_SIGCHAR_CC_PREFIX), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_DEFAULT", newSVpv(form("%c", DC_SIGCHAR_CC_DEFAULT), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_THISCALL", newSVpv(form("%c", DC_SIGCHAR_CC_THISCALL), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_ELLIPSIS", newSVpv(form("%c", DC_SIGCHAR_CC_ELLIPSIS), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_ELLIPSIS_VARARGS",
                newSVpv(form("%c", DC_SIGCHAR_CC_ELLIPSIS_VARARGS), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_CDECL", newSVpv(form("%c", DC_SIGCHAR_CC_CDECL), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_STDCALL", newSVpv(form("%c", DC_SIGCHAR_CC_STDCALL), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_FASTCALL_MS",
                newSVpv(form("%c", DC_SIGCHAR_CC_FASTCALL_MS), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_FASTCALL_GNU",
                newSVpv(form("%c", DC_SIGCHAR_CC_FASTCALL_GNU), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_THISCALL_MS",
                newSVpv(form("%c", DC_SIGCHAR_CC_THISCALL_MS), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_THISCALL_GNU",
                newSVpv(form("%c", DC_SIGCHAR_CC_THISCALL_GNU), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_ARM_ARM", newSVpv(form("%c", DC_SIGCHAR_CC_ARM_ARM), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_ARM_THUMB", newSVpv(form("%c", DC_SIGCHAR_CC_ARM_THUMB), 1));
    newCONSTSUB(stash, "DC_SIGCHAR_CC_SYSCALL", newSVpv(form("%c", DC_SIGCHAR_CC_SYSCALL), 1));

    // Error codes
    newCONSTSUB(stash, "DC_ERROR_NONE", newSViv(DC_ERROR_NONE));
    newCONSTSUB(stash, "DC_ERROR_UNSUPPORTED_MODE", newSViv(DC_ERROR_UNSUPPORTED_MODE));

    export_function("Dyn::Call", "dcNewCallVM", "call");
    export_function("Dyn::Call", "dcFree", "call");
    export_function("Dyn::Call", "dcMode", "call");
    export_function("Dyn::Call", "dcReset", "call");

    export_function("Dyn::Call", "dcArgBool", "call");
    export_function("Dyn::Call", "dcArgChar", "call");
    export_function("Dyn::Call", "dcArgShort", "call");
    export_function("Dyn::Call", "dcArgInt", "call");
    export_function("Dyn::Call", "dcArgLong", "call");
    export_function("Dyn::Call", "dcArgLongLong", "call");
    export_function("Dyn::Call", "dcArgFloat", "call");
    export_function("Dyn::Call", "dcArgDouble", "call");
    export_function("Dyn::Call", "dcArgPointer", "call");
    export_function("Dyn::Call", "dcArgString", "call");
    export_function("Dyn::Call", "dcArgAggr", "call");

    export_function("Dyn::Call", "dcCallVoid", "call");
    export_function("Dyn::Call", "dcCallBool", "call");
    export_function("Dyn::Call", "dcCallChar", "call");
    export_function("Dyn::Call", "dcCallShort", "call");
    export_function("Dyn::Call", "dcCallInt", "call");
    export_function("Dyn::Call", "dcCallLong", "call");
    export_function("Dyn::Call", "dcCallLongLong", "call");
    export_function("Dyn::Call", "dcCallFloat", "call");
    export_function("Dyn::Call", "dcCallDouble", "call");
    export_function("Dyn::Call", "dcCallPointer", "call");
    export_function("Dyn::Call", "dcCallString", "call");
    export_function("Dyn::Call", "dcCallAggr", "call");
    export_function("Dyn::Call", "dcBeginCallAggr", "call");

    export_function("Dyn::Call", "DC_CALL_C_DEFAULT", "vars");
    export_function("Dyn::Call", "DC_CALL_C_ELLIPSIS", "vars");
    export_function("Dyn::Call", "DC_CALL_C_ELLIPSIS_VARARGS", "vars");
    export_function("Dyn::Call", "DC_CALL_C_X86_CDECL", "vars");
    export_function("Dyn::Call", "DC_CALL_C_X86_WIN32_STD", "vars");
    export_function("Dyn::Call", "DC_CALL_C_X86_WIN32_FAST_MS", "vars");
    export_function("Dyn::Call", "DC_CALL_C_X86_WIN32_FAST_GNU", "vars");
    export_function("Dyn::Call", "DC_CALL_C_X86_WIN32_THIS_MS", "vars");
    export_function("Dyn::Call", "DC_CALL_C_X86_WIN32_THIS_GNU", "vars");
    export_function("Dyn::Call", "DC_CALL_C_X64_WIN64", "vars");
    export_function("Dyn::Call", "DC_CALL_C_X64_SYSV", "vars");
    export_function("Dyn::Call", "DC_CALL_C_PPC32_DARWIN", "vars");
    export_function("Dyn::Call", "DC_CALL_C_PPC32_OSX", "vars");
    export_function("Dyn::Call", "DC_CALL_C_ARM_ARM_EABI", "vars");
    export_function("Dyn::Call", "DC_CALL_C_ARM_THUMB_EABI", "vars");
    export_function("Dyn::Call", "DC_CALL_C_ARM_ARMHF", "vars");
    export_function("Dyn::Call", "DC_CALL_C_MIPS32_EABI", "vars");
    export_function("Dyn::Call", "DC_CALL_C_MIPS32_PSPSDK", "vars");
    export_function("Dyn::Call", "DC_CALL_C_PPC32_SYSV", "vars");
    export_function("Dyn::Call", "DC_CALL_C_PPC32_LINUX", "vars");
    export_function("Dyn::Call", "DC_CALL_C_ARM_ARM", "vars");
    export_function("Dyn::Call", "DC_CALL_C_ARM_THUMB", "vars");
    export_function("Dyn::Call", "DC_CALL_C_MIPS32_O32", "vars");
    export_function("Dyn::Call", "DC_CALL_C_MIPS64_N32", "vars");
    export_function("Dyn::Call", "DC_CALL_C_MIPS64_N64", "vars");
    export_function("Dyn::Call", "DC_CALL_C_X86_PLAN9", "vars");
    export_function("Dyn::Call", "DC_CALL_C_SPARC32", "vars");
    export_function("Dyn::Call", "DC_CALL_C_SPARC64", "vars");
    export_function("Dyn::Call", "DC_CALL_C_ARM64", "vars");
    export_function("Dyn::Call", "DC_CALL_C_PPC64", "vars");
    export_function("Dyn::Call", "DC_CALL_C_PPC64_LINUX", "vars");
    export_function("Dyn::Call", "DC_CALL_SYS_DEFAULT", "vars");
    export_function("Dyn::Call", "DC_CALL_SYS_X86_INT80H_LINUX", "vars");
    export_function("Dyn::Call", "DC_CALL_SYS_X86_INT80H_BSD", "vars");
    export_function("Dyn::Call", "DC_CALL_SYS_PPC32", "vars");
    export_function("Dyn::Call", "DC_CALL_SYS_PPC64", "vars");

    export_function("Dyn::Call", "DC_ERROR_NONE", "vars");
    export_function("Dyn::Call", "DC_ERROR_UNSUPPORTED_MODE", "vars");

    export_function("Dyn::Call", "DC_SIGCHAR_VOID", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_BOOL", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CHAR", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_UCHAR", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_SHORT", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_USHORT", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_INT", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_UINT", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_LONG", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_ULONG", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_LONGLONG", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_ULONGLONG", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_FLOAT", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_DOUBLE", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_POINTER", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_STRING", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_STRUCT", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_ENDARG", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_PREFIX", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_DEFAULT", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_ELLIPSIS", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_ELLIPSIS_VARARGS", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_CDECL", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_STDCALL", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_THISCALL", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_FASTCALL_MS", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_FASTCALL_GNU", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_THISCALL_MS", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_THISCALL_GNU", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_ARM_ARM", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_ARM_THUMB", "sigchar");
    export_function("Dyn::Call", "DC_SIGCHAR_CC_SYSCALL", "sigchar");
    export_function("Dyn::Call", "DEFAULT_ALIGNMENT", "vars");
}
// clang-format off

INCLUDE: Call/Aggregate.xsh

INCLUDE: Call/Pointer.xsh