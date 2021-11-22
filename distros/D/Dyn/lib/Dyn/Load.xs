#include "lib/xshelper.h"

#include <dynload.h>
#include <dyncall.h>
#include <dyncall_value.h>
#include <dyncall_callf.h>
#include <dyncall_signature.h>
#include <dyncall_callback.h>

#include "lib/types.h"

MODULE = Dyn::Load PACKAGE = Dyn::Load

DLLib *
dlLoadLibrary(const char * libpath)
INIT:
    if (ST(0) == (SV*) &PL_sv_undef)
        libpath = (const char *) NULL; // This still doesn't seem to work under perl

void
dlFreeLibrary(DLLib * pLib)
CODE:
    dlFreeLibrary(pLib);
    SV* sv = (SV*) &PL_sv_undef;
    sv_setsv(ST(0), sv);

DCpointer
dlFindSymbol(DLLib * pLib, const char * pSymbolName);

int
dlGetLibraryPath(DLLib * pLib, char * sOut, int bufSize);
CODE:
    char bin[bufSize];
    RETVAL = dlGetLibraryPath(pLib, bin, bufSize);
    sv_setpv((SV*)ST(1), bin);
    SvSETMAGIC(ST(1));
OUTPUT:
    RETVAL

DLSyms *
dlSymsInit(const char * libPath);

void
dlSymsCleanup(DLSyms * pSyms);
CODE:
    dlSymsCleanup(pSyms);
    SV* sv = (SV*) &PL_sv_undef;
    sv_setsv(ST(0), sv);

int
dlSymsCount(DLSyms * pSyms);

const char*
dlSymsName(DLSyms * pSyms, int index);

const char*
dlSymsNameFromValue(DLSyms * pSyms, void * value)
