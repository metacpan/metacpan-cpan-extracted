#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newCONSTSUB
#define NEED_sv_2pv_nolen
#include "ppport.h"

#include <fnmatch.h>

/* $Id: FnMatch.xs,v 1.2 2005/03/30 05:34:57 mjp Exp $ */

MODULE = File::FnMatch		PACKAGE = File::FnMatch		

int
fnmatch(pattern, ...)
    char * pattern

    PROTOTYPE: $$;$

    CODE:
    char * string;
    int flags;

    if (items < 2 || items > 3)
        croak("Usage: File::FnMatch::fnmatch(pattern, string, flags=0)");

    string = (char *)SvPV_nolen(ST(1));

    if (items < 3)
        flags = 0;
    else
        flags = (int)SvIV(ST(2));

    RETVAL = !(fnmatch(pattern, string, flags));

    OUTPUT:
    RETVAL

BOOT:
{
    HV *stash = gv_stashpvn("File::FnMatch", 13, TRUE);
    struct { char *n; I32 v; } File__FnMatch__const[] = {
#ifdef FNM_NOESCAPE
    {"FNM_NOESCAPE", FNM_NOESCAPE},
#endif
#ifdef FNM_PATHNAME
    {"FNM_PATHNAME", FNM_PATHNAME},
#endif
#ifdef FNM_FILE_NAME
    {"FNM_FILE_NAME", FNM_FILE_NAME},
#endif
#ifdef FNM_PERIOD
    {"FNM_PERIOD", FNM_PERIOD},
#endif
#ifdef FNM_LEADING_DIR
    {"FNM_LEADING_DIR", FNM_LEADING_DIR},
#endif
#ifdef FNM_CASEFOLD
    {"FNM_CASEFOLD", FNM_CASEFOLD},
#endif
#ifdef FNM_EXTMATCH
    {"FNM_EXTMATCH", FNM_EXTMATCH},
#endif
    {Nullch, 0}};
    char *name;
    int i;

    for (i = 0; name = File__FnMatch__const[i].n; i++) {
        newCONSTSUB(stash, name, newSViv(File__FnMatch__const[i].v));
    }
}
