//-----------------------------------------------------------------------------
//
// MNG.xs
//
// Written by David Mott, SEP 10/24/2001
//
//
// The Graphics::MNG module is Copyright (c) 2001 David P. Mott, USA (dpmott@sep.com)
// (this includes MNG.pm, MNG.xs, typemap, and all test scripts (t*.pl))
// All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the same terms as Perl itself (i.e. GPL or Artistic).
//
//
//-----------------------------------------------------------------------------

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

// need to fix lcms.h conditions...
#if defined(WIN32)
//#include <windows.h>
#endif
#include <Lcms.h>
#include <libmng.h>
#include <libmng_types.h>
#include <libmng_conf.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_MNG_NOC(char *name, int len, int arg)
{
    switch (name[7 + 0]) {
    case 'A':
	if (strEQ(name + 7, "ALLBACK")) {	/* MNG_NOC removed */
#ifdef MNG_NOCALLBACK
	    return MNG_NOCALLBACK;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 7, "ORRCHUNK")) {	/* MNG_NOC removed */
#ifdef MNG_NOCORRCHUNK
	    return MNG_NOCORRCHUNK;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_NOT(char *name, int len, int arg)
{
    switch (name[7 + 0]) {
    case 'A':
	if (strEQ(name + 7, "ANANIMATION")) {	/* MNG_NOT removed */
#ifdef MNG_NOTANANIMATION
	    return MNG_NOTANANIMATION;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 7, "ENOUGHIDAT")) {	/* MNG_NOT removed */
#ifdef MNG_NOTENOUGHIDAT
	    return MNG_NOTENOUGHIDAT;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 7, "VIEWABLE")) {	/* MNG_NOT removed */
#ifdef MNG_NOTVIEWABLE
	    return MNG_NOTVIEWABLE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_NO(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'C':
	return constant_MNG_NOC(name, len, arg);
    case 'E':
	if (strEQ(name + 6, "ERROR")) {	/* MNG_NO removed */
#ifdef MNG_NOERROR
	    return MNG_NOERROR;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 6, "HEADER")) {	/* MNG_NO removed */
#ifdef MNG_NOHEADER
	    return MNG_NOHEADER;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 6, "MHDR")) {	/* MNG_NO removed */
#ifdef MNG_NOMHDR
	    return MNG_NOMHDR;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 6, "OUTPUTPROFILE")) {	/* MNG_NO removed */
#ifdef MNG_NOOUTPUTPROFILE
	    return MNG_NOOUTPUTPROFILE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 6, "SRGBPROFILE")) {	/* MNG_NO removed */
#ifdef MNG_NOSRGBPROFILE
	    return MNG_NOSRGBPROFILE;
#else
	    goto not_there;
#endif
	}
    case 'T':
	return constant_MNG_NOT(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_NU(char *name, int len, int arg)
{
    if (6 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 2]) {
    case '\0':
	if (strEQ(name + 6, "LL")) {	/* MNG_NU removed */
#ifdef MNG_NULL
	    return MNG_NULL;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 6, "LLNOTFOUND")) {	/* MNG_NU removed */
#ifdef MNG_NULLNOTFOUND
	    return MNG_NULLNOTFOUND;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_NE(char *name, int len, int arg)
{
    if (6 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 2]) {
    case 'M':
	if (strEQ(name + 6, "EDMOREDATA")) {	/* MNG_NE removed */
#ifdef MNG_NEEDMOREDATA
	    return MNG_NEEDMOREDATA;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 6, "EDSECTIONWAIT")) {	/* MNG_NE removed */
#ifdef MNG_NEEDSECTIONWAIT
	    return MNG_NEEDSECTIONWAIT;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 6, "EDTIMERWAIT")) {	/* MNG_NE removed */
#ifdef MNG_NEEDTIMERWAIT
	    return MNG_NEEDTIMERWAIT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_N(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'E':
	return constant_MNG_NE(name, len, arg);
    case 'O':
	return constant_MNG_NO(name, len, arg);
    case 'U':
	return constant_MNG_NU(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_OF(char *name, int len, int arg)
{
    if (6 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 5]) {
    case 'A':
	if (strEQ(name + 6, "FSET_ABSOLUTE")) {	/* MNG_OF removed */
#ifdef MNG_OFFSET_ABSOLUTE
	    return MNG_OFFSET_ABSOLUTE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 6, "FSET_RELATIVE")) {	/* MNG_OF removed */
#ifdef MNG_OFFSET_RELATIVE
	    return MNG_OFFSET_RELATIVE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_ORIENTATION_F(char *name, int len, int arg)
{
    if (17 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 3]) {
    case 'H':
	if (strEQ(name + 17, "LIPHORZ")) {	/* MNG_ORIENTATION_F removed */
#ifdef MNG_ORIENTATION_FLIPHORZ
	    return MNG_ORIENTATION_FLIPHORZ;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 17, "LIPVERT")) {	/* MNG_ORIENTATION_F removed */
#ifdef MNG_ORIENTATION_FLIPVERT
	    return MNG_ORIENTATION_FLIPVERT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_OR(char *name, int len, int arg)
{
    if (6 + 10 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 10]) {
    case '1':
	if (strEQ(name + 6, "IENTATION_180DEG")) {	/* MNG_OR removed */
#ifdef MNG_ORIENTATION_180DEG
	    return MNG_ORIENTATION_180DEG;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (!strnEQ(name + 6,"IENTATION_", 10))
	    break;
	return constant_MNG_ORIENTATION_F(name, len, arg);
    case 'S':
	if (strEQ(name + 6, "IENTATION_SAME")) {	/* MNG_OR removed */
#ifdef MNG_ORIENTATION_SAME
	    return MNG_ORIENTATION_SAME;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 6, "IENTATION_TILED")) {	/* MNG_OR removed */
#ifdef MNG_ORIENTATION_TILED
	    return MNG_ORIENTATION_TILED;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_OBJE(char *name, int len, int arg)
{
    if (8 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 2]) {
    case 'E':
	if (strEQ(name + 8, "CTEXISTS")) {	/* MNG_OBJE removed */
#ifdef MNG_OBJECTEXISTS
	    return MNG_OBJECTEXISTS;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 8, "CTUNKNOWN")) {	/* MNG_OBJE removed */
#ifdef MNG_OBJECTUNKNOWN
	    return MNG_OBJECTUNKNOWN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_OB(char *name, int len, int arg)
{
    if (6 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'E':
	if (!strnEQ(name + 6,"J", 1))
	    break;
	return constant_MNG_OBJE(name, len, arg);
    case 'N':
	if (strEQ(name + 6, "JNOTCONCRETE")) {	/* MNG_OB removed */
#ifdef MNG_OBJNOTCONCRETE
	    return MNG_OBJNOTCONCRETE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_OU(char *name, int len, int arg)
{
    if (6 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'O':
	if (strEQ(name + 6, "TOFMEMORY")) {	/* MNG_OU removed */
#ifdef MNG_OUTOFMEMORY
	    return MNG_OUTOFMEMORY;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 6, "TPUTERROR")) {	/* MNG_OU removed */
#ifdef MNG_OUTPUTERROR
	    return MNG_OUTPUTERROR;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_O(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'B':
	return constant_MNG_OB(name, len, arg);
    case 'F':
	return constant_MNG_OF(name, len, arg);
    case 'R':
	return constant_MNG_OR(name, len, arg);
    case 'U':
	return constant_MNG_OU(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_PN(char *name, int len, int arg)
{
    if (6 + 11 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 11]) {
    case 'A':
	if (strEQ(name + 6, "G_VERSION_MAJ")) {	/* MNG_PN removed */
#ifdef MNG_PNG_VERSION_MAJ
	    return MNG_PNG_VERSION_MAJ;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 6, "G_VERSION_MIN")) {	/* MNG_PN removed */
#ifdef MNG_PNG_VERSION_MIN
	    return MNG_PNG_VERSION_MIN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_PO(char *name, int len, int arg)
{
    if (6 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 7]) {
    case 'A':
	if (strEQ(name + 6, "LARITY_ALLBUT")) {	/* MNG_PO removed */
#ifdef MNG_POLARITY_ALLBUT
	    return MNG_POLARITY_ALLBUT;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 6, "LARITY_ONLY")) {	/* MNG_PO removed */
#ifdef MNG_POLARITY_ONLY
	    return MNG_POLARITY_ONLY;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_PR(char *name, int len, int arg)
{
    if (6 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 7]) {
    case 'A':
	if (strEQ(name + 6, "IORITY_ABSOLUTE")) {	/* MNG_PR removed */
#ifdef MNG_PRIORITY_ABSOLUTE
	    return MNG_PRIORITY_ABSOLUTE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 6, "IORITY_RELATIVE")) {	/* MNG_PR removed */
#ifdef MNG_PRIORITY_RELATIVE
	    return MNG_PRIORITY_RELATIVE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_PLT(char *name, int len, int arg)
{
    if (7 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 1]) {
    case 'I':
	if (strEQ(name + 7, "EINDEXERROR")) {	/* MNG_PLT removed */
#ifdef MNG_PLTEINDEXERROR
	    return MNG_PLTEINDEXERROR;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 7, "EMISSING")) {	/* MNG_PLT removed */
#ifdef MNG_PLTEMISSING
	    return MNG_PLTEMISSING;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_PL(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'A':
	if (strEQ(name + 6, "AYTIMETOOHIGH")) {	/* MNG_PL removed */
#ifdef MNG_PLAYTIMETOOHIGH
	    return MNG_PLAYTIMETOOHIGH;
#else
	    goto not_there;
#endif
	}
    case 'T':
	return constant_MNG_PLT(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_P(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	if (strEQ(name + 5, "ARTIAL_CLONE")) {	/* MNG_P removed */
#ifdef MNG_PARTIAL_CLONE
	    return MNG_PARTIAL_CLONE;
#else
	    goto not_there;
#endif
	}
    case 'L':
	return constant_MNG_PL(name, len, arg);
    case 'N':
	return constant_MNG_PN(name, len, arg);
    case 'O':
	return constant_MNG_PO(name, len, arg);
    case 'R':
	return constant_MNG_PR(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_APPT(char *name, int len, int arg)
{
    switch (name[8 + 0]) {
    case 'I':
	if (strEQ(name + 8, "IMERERROR")) {	/* MNG_APPT removed */
#ifdef MNG_APPTIMERERROR
	    return MNG_APPTIMERERROR;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 8, "RACEABORT")) {	/* MNG_APPT removed */
#ifdef MNG_APPTRACEABORT
	    return MNG_APPTRACEABORT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_AP(char *name, int len, int arg)
{
    if (6 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'C':
	if (strEQ(name + 6, "PCMSERROR")) {	/* MNG_AP removed */
#ifdef MNG_APPCMSERROR
	    return MNG_APPCMSERROR;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 6, "PIOERROR")) {	/* MNG_AP removed */
#ifdef MNG_APPIOERROR
	    return MNG_APPIOERROR;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 6, "PMISCERROR")) {	/* MNG_AP removed */
#ifdef MNG_APPMISCERROR
	    return MNG_APPMISCERROR;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (!strnEQ(name + 6,"P", 1))
	    break;
	return constant_MNG_APPT(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_A(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'B':
	if (strEQ(name + 5, "BSTRACT")) {	/* MNG_A removed */
#ifdef MNG_ABSTRACT
	    return MNG_ABSTRACT;
#else
	    goto not_there;
#endif
	}
    case 'C':
	if (strEQ(name + 5, "CCESS_CHUNKS")) {	/* MNG_A removed */
#ifdef MNG_ACCESS_CHUNKS
	    return 1; // MNG_ACCESS_CHUNKS; 
#else
	    return 0; // goto not_there;
#endif
	}
    case 'P':
	return constant_MNG_AP(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_BO(char *name, int len, int arg)
{
    if (6 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 7]) {
    case 'A':
	if (strEQ(name + 6, "UNDARY_ABSOLUTE")) {	/* MNG_BO removed */
#ifdef MNG_BOUNDARY_ABSOLUTE
	    return MNG_BOUNDARY_ABSOLUTE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 6, "UNDARY_RELATIVE")) {	/* MNG_BO removed */
#ifdef MNG_BOUNDARY_RELATIVE
	    return MNG_BOUNDARY_RELATIVE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_BITDEPTH_1(char *name, int len, int arg)
{
    switch (name[14 + 0]) {
    case '\0':
	if (strEQ(name + 14, "")) {	/* MNG_BITDEPTH_1 removed */
#ifdef MNG_BITDEPTH_1
	    return MNG_BITDEPTH_1;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 14, "6")) {	/* MNG_BITDEPTH_1 removed */
#ifdef MNG_BITDEPTH_16
	    return MNG_BITDEPTH_16;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_BITDEPTH_JPEG8(char *name, int len, int arg)
{
    switch (name[18 + 0]) {
    case '\0':
	if (strEQ(name + 18, "")) {	/* MNG_BITDEPTH_JPEG8 removed */
#ifdef MNG_BITDEPTH_JPEG8
	    return MNG_BITDEPTH_JPEG8;
#else
	    goto not_there;
#endif
	}
    case 'A':
	if (strEQ(name + 18, "AND12")) {	/* MNG_BITDEPTH_JPEG8 removed */
#ifdef MNG_BITDEPTH_JPEG8AND12
	    return MNG_BITDEPTH_JPEG8AND12;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_BITDEPTH_J(char *name, int len, int arg)
{
    if (14 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[14 + 3]) {
    case '1':
	if (strEQ(name + 14, "PEG12")) {	/* MNG_BITDEPTH_J removed */
#ifdef MNG_BITDEPTH_JPEG12
	    return MNG_BITDEPTH_JPEG12;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (!strnEQ(name + 14,"PEG", 3))
	    break;
	return constant_MNG_BITDEPTH_JPEG8(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_BI(char *name, int len, int arg)
{
    if (6 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 7]) {
    case '1':
	if (!strnEQ(name + 6,"TDEPTH_", 7))
	    break;
	return constant_MNG_BITDEPTH_1(name, len, arg);
    case '2':
	if (strEQ(name + 6, "TDEPTH_2")) {	/* MNG_BI removed */
#ifdef MNG_BITDEPTH_2
	    return MNG_BITDEPTH_2;
#else
	    goto not_there;
#endif
	}
    case '4':
	if (strEQ(name + 6, "TDEPTH_4")) {	/* MNG_BI removed */
#ifdef MNG_BITDEPTH_4
	    return MNG_BITDEPTH_4;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (strEQ(name + 6, "TDEPTH_8")) {	/* MNG_BI removed */
#ifdef MNG_BITDEPTH_8
	    return MNG_BITDEPTH_8;
#else
	    goto not_there;
#endif
	}
    case 'J':
	if (!strnEQ(name + 6,"TDEPTH_", 7))
	    break;
	return constant_MNG_BITDEPTH_J(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_BACKGROUNDI(char *name, int len, int arg)
{
    if (15 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 5]) {
    case 'M':
	if (strEQ(name + 15, "MAGE_MANDATORY")) {	/* MNG_BACKGROUNDI removed */
#ifdef MNG_BACKGROUNDIMAGE_MANDATORY
	    return MNG_BACKGROUNDIMAGE_MANDATORY;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 15, "MAGE_NOTILE")) {	/* MNG_BACKGROUNDI removed */
#ifdef MNG_BACKGROUNDIMAGE_NOTILE
	    return MNG_BACKGROUNDIMAGE_NOTILE;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 15, "MAGE_TILE")) {	/* MNG_BACKGROUNDI removed */
#ifdef MNG_BACKGROUNDIMAGE_TILE
	    return MNG_BACKGROUNDIMAGE_TILE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_BA(char *name, int len, int arg)
{
    if (6 + 8 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 8]) {
    case 'C':
	if (strEQ(name + 6, "CKGROUNDCOLOR_MANDATORY")) {	/* MNG_BA removed */
#ifdef MNG_BACKGROUNDCOLOR_MANDATORY
	    return MNG_BACKGROUNDCOLOR_MANDATORY;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (!strnEQ(name + 6,"CKGROUND", 8))
	    break;
	return constant_MNG_BACKGROUNDI(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_B(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	return constant_MNG_BA(name, len, arg);
    case 'I':
	return constant_MNG_BI(name, len, arg);
    case 'O':
	return constant_MNG_BO(name, len, arg);
    case 'U':
	if (strEQ(name + 5, "UFOVERFLOW")) {	/* MNG_B removed */
#ifdef MNG_BUFOVERFLOW
	    return MNG_BUFOVERFLOW;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_SH(char *name, int len, int arg)
{
    if (6 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 7]) {
    case '0':
	if (strEQ(name + 6, "OWMODE_0")) {	/* MNG_SH removed */
#ifdef MNG_SHOWMODE_0
	    return MNG_SHOWMODE_0;
#else
	    goto not_there;
#endif
	}
    case '1':
	if (strEQ(name + 6, "OWMODE_1")) {	/* MNG_SH removed */
#ifdef MNG_SHOWMODE_1
	    return MNG_SHOWMODE_1;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 6, "OWMODE_2")) {	/* MNG_SH removed */
#ifdef MNG_SHOWMODE_2
	    return MNG_SHOWMODE_2;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 6, "OWMODE_3")) {	/* MNG_SH removed */
#ifdef MNG_SHOWMODE_3
	    return MNG_SHOWMODE_3;
#else
	    goto not_there;
#endif
	}
    case '4':
	if (strEQ(name + 6, "OWMODE_4")) {	/* MNG_SH removed */
#ifdef MNG_SHOWMODE_4
	    return MNG_SHOWMODE_4;
#else
	    goto not_there;
#endif
	}
    case '5':
	if (strEQ(name + 6, "OWMODE_5")) {	/* MNG_SH removed */
#ifdef MNG_SHOWMODE_5
	    return MNG_SHOWMODE_5;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 6, "OWMODE_6")) {	/* MNG_SH removed */
#ifdef MNG_SHOWMODE_6
	    return MNG_SHOWMODE_6;
#else
	    goto not_there;
#endif
	}
    case '7':
	if (strEQ(name + 6, "OWMODE_7")) {	/* MNG_SH removed */
#ifdef MNG_SHOWMODE_7
	    return MNG_SHOWMODE_7;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_SI(char *name, int len, int arg)
{
    if (6 + 9 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 9]) {
    case 'C':
	if (strEQ(name + 6, "MPLICITY_COMPLEXFEATURES")) {	/* MNG_SI removed */
#ifdef MNG_SIMPLICITY_COMPLEXFEATURES
	    return MNG_SIMPLICITY_COMPLEXFEATURES;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 6, "MPLICITY_DELTAPNG")) {	/* MNG_SI removed */
#ifdef MNG_SIMPLICITY_DELTAPNG
	    return MNG_SIMPLICITY_DELTAPNG;
#else
	    goto not_there;
#endif
	}
    case 'J':
	if (strEQ(name + 6, "MPLICITY_JNG")) {	/* MNG_SI removed */
#ifdef MNG_SIMPLICITY_JNG
	    return MNG_SIMPLICITY_JNG;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 6, "MPLICITY_SIMPLEFEATURES")) {	/* MNG_SI removed */
#ifdef MNG_SIMPLICITY_SIMPLEFEATURES
	    return MNG_SIMPLICITY_SIMPLEFEATURES;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 6, "MPLICITY_TRANSPARENCY")) {	/* MNG_SI removed */
#ifdef MNG_SIMPLICITY_TRANSPARENCY
	    return MNG_SIMPLICITY_TRANSPARENCY;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 6, "MPLICITY_VALID")) {	/* MNG_SI removed */
#ifdef MNG_SIMPLICITY_VALID
	    return MNG_SIMPLICITY_VALID;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_SAVEO(char *name, int len, int arg)
{
    if (9 + 6 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 6]) {
    case '4':
	if (strEQ(name + 9, "FFSET_4BYTE")) {	/* MNG_SAVEO removed */
#ifdef MNG_SAVEOFFSET_4BYTE
	    return MNG_SAVEOFFSET_4BYTE;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (strEQ(name + 9, "FFSET_8BYTE")) {	/* MNG_SAVEO removed */
#ifdef MNG_SAVEOFFSET_8BYTE
	    return MNG_SAVEOFFSET_8BYTE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_SAVEENTRY_SE(char *name, int len, int arg)
{
    if (16 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[16 + 5]) {
    case '\0':
	if (strEQ(name + 16, "GMENT")) {	/* MNG_SAVEENTRY_SE removed */
#ifdef MNG_SAVEENTRY_SEGMENT
	    return MNG_SAVEENTRY_SEGMENT;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 16, "GMENTFULL")) {	/* MNG_SAVEENTRY_SE removed */
#ifdef MNG_SAVEENTRY_SEGMENTFULL
	    return MNG_SAVEENTRY_SEGMENTFULL;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_SAVEENTRY_S(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case 'E':
	return constant_MNG_SAVEENTRY_SE(name, len, arg);
    case 'U':
	if (strEQ(name + 15, "UBFRAME")) {	/* MNG_SAVEENTRY_S removed */
#ifdef MNG_SAVEENTRY_SUBFRAME
	    return MNG_SAVEENTRY_SUBFRAME;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_SAVEE(char *name, int len, int arg)
{
    if (9 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 5]) {
    case 'E':
	if (strEQ(name + 9, "NTRY_EXPORTEDIMAGE")) {	/* MNG_SAVEE removed */
#ifdef MNG_SAVEENTRY_EXPORTEDIMAGE
	    return MNG_SAVEENTRY_EXPORTEDIMAGE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (!strnEQ(name + 9,"NTRY_", 5))
	    break;
	return constant_MNG_SAVEENTRY_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_SA(char *name, int len, int arg)
{
    if (6 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 2]) {
    case 'E':
	if (!strnEQ(name + 6,"VE", 2))
	    break;
	return constant_MNG_SAVEE(name, len, arg);
    case 'O':
	if (!strnEQ(name + 6,"VE", 2))
	    break;
	return constant_MNG_SAVEO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_SUP(char *name, int len, int arg)
{
    if (7 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 5]) {
    case 'D':
	if (strEQ(name + 7, "PORT_DISPLAY")) {	/* MNG_SUP removed */
#ifdef MNG_SUPPORT_DISPLAY
	    return 1; // MNG_SUPPORT_DISPLAY; 
#else
	    return 0; // goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 7, "PORT_FULL")) {	/* MNG_SUP removed */
#ifdef MNG_SUPPORT_FULL
	    return 1; // MNG_SUPPORT_FULL;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 7, "PORT_IJG6B")) {	/* MNG_SUP removed */
#ifdef MNG_SUPPORT_IJG6B
	    return 1; // MNG_SUPPORT_IJG6B;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'J':
	if (strEQ(name + 7, "PORT_JPEG8")) {	/* MNG_SUP removed */
#ifdef MNG_SUPPORT_JPEG8
	    return 1; // MNG_SUPPORT_JPEG8;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 7, "PORT_READ")) {	/* MNG_SUP removed */
#ifdef MNG_SUPPORT_READ
	    return 1; // MNG_SUPPORT_READ;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'W':
	if (strEQ(name + 7, "PORT_WRITE")) {	/* MNG_SUP removed */
#ifdef MNG_SUPPORT_WRITE
	    return 1; // MNG_SUPPORT_WRITE;
#else
	    return 0; // goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_SUS(char *name, int len, int arg)
{
    if (7 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 4]) {
    case 'B':
	if (strEQ(name + 7, "PENDBUFFERSIZE")) {	/* MNG_SUS removed */
#ifdef MNG_SUSPENDBUFFERSIZE
	    return MNG_SUSPENDBUFFERSIZE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 7, "PENDREQUESTSIZE")) {	/* MNG_SUS removed */
#ifdef MNG_SUSPENDREQUESTSIZE
	    return MNG_SUSPENDREQUESTSIZE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_SU(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'P':
	return constant_MNG_SUP(name, len, arg);
    case 'S':
	return constant_MNG_SUS(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_S(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	return constant_MNG_SA(name, len, arg);
    case 'E':
	if (strEQ(name + 5, "EQUENCEERROR")) {	/* MNG_S removed */
#ifdef MNG_SEQUENCEERROR
	    return MNG_SEQUENCEERROR;
#else
	    goto not_there;
#endif
	}
    case 'H':
	return constant_MNG_SH(name, len, arg);
    case 'I':
	return constant_MNG_SI(name, len, arg);
    case 'T':
	if (strEQ(name + 5, "TORE_CHUNKS")) {	/* MNG_S removed */
#ifdef MNG_STORE_CHUNKS
	    return 1; // MNG_STORE_CHUNKS;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'U':
	return constant_MNG_SU(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CONCRETE_(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case 'A':
	if (strEQ(name + 13, "ASPARENT")) {	/* MNG_CONCRETE_ removed */
#ifdef MNG_CONCRETE_ASPARENT
	    return MNG_CONCRETE_ASPARENT;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 13, "MAKEABSTRACT")) {	/* MNG_CONCRETE_ removed */
#ifdef MNG_CONCRETE_MAKEABSTRACT
	    return MNG_CONCRETE_MAKEABSTRACT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CON(char *name, int len, int arg)
{
    if (7 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 5]) {
    case '\0':
	if (strEQ(name + 7, "CRETE")) {	/* MNG_CON removed */
#ifdef MNG_CONCRETE
	    return MNG_CONCRETE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 7,"CRETE", 5))
	    break;
	return constant_MNG_CONCRETE_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_COLORTYPE_G(char *name, int len, int arg)
{
    if (15 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 3]) {
    case '\0':
	if (strEQ(name + 15, "RAY")) {	/* MNG_COLORTYPE_G removed */
#ifdef MNG_COLORTYPE_GRAY
	    return MNG_COLORTYPE_GRAY;
#else
	    goto not_there;
#endif
	}
    case 'A':
	if (strEQ(name + 15, "RAYA")) {	/* MNG_COLORTYPE_G removed */
#ifdef MNG_COLORTYPE_GRAYA
	    return MNG_COLORTYPE_GRAYA;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_COLORTYPE_R(char *name, int len, int arg)
{
    if (15 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 2]) {
    case '\0':
	if (strEQ(name + 15, "GB")) {	/* MNG_COLORTYPE_R removed */
#ifdef MNG_COLORTYPE_RGB
	    return MNG_COLORTYPE_RGB;
#else
	    goto not_there;
#endif
	}
    case 'A':
	if (strEQ(name + 15, "GBA")) {	/* MNG_COLORTYPE_R removed */
#ifdef MNG_COLORTYPE_RGBA
	    return MNG_COLORTYPE_RGBA;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_COLORTYPE_JPEGG(char *name, int len, int arg)
{
    if (19 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 3]) {
    case '\0':
	if (strEQ(name + 19, "RAY")) {	/* MNG_COLORTYPE_JPEGG removed */
#ifdef MNG_COLORTYPE_JPEGGRAY
	    return MNG_COLORTYPE_JPEGGRAY;
#else
	    goto not_there;
#endif
	}
    case 'A':
	if (strEQ(name + 19, "RAYA")) {	/* MNG_COLORTYPE_JPEGG removed */
#ifdef MNG_COLORTYPE_JPEGGRAYA
	    return MNG_COLORTYPE_JPEGGRAYA;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_COLORTYPE_JPEGC(char *name, int len, int arg)
{
    if (19 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 4]) {
    case '\0':
	if (strEQ(name + 19, "OLOR")) {	/* MNG_COLORTYPE_JPEGC removed */
#ifdef MNG_COLORTYPE_JPEGCOLOR
	    return MNG_COLORTYPE_JPEGCOLOR;
#else
	    goto not_there;
#endif
	}
    case 'A':
	if (strEQ(name + 19, "OLORA")) {	/* MNG_COLORTYPE_JPEGC removed */
#ifdef MNG_COLORTYPE_JPEGCOLORA
	    return MNG_COLORTYPE_JPEGCOLORA;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_COLORTYPE_J(char *name, int len, int arg)
{
    if (15 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 3]) {
    case 'C':
	if (!strnEQ(name + 15,"PEG", 3))
	    break;
	return constant_MNG_COLORTYPE_JPEGC(name, len, arg);
    case 'G':
	if (!strnEQ(name + 15,"PEG", 3))
	    break;
	return constant_MNG_COLORTYPE_JPEGG(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_COL(char *name, int len, int arg)
{
    if (7 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 7]) {
    case 'G':
	if (!strnEQ(name + 7,"ORTYPE_", 7))
	    break;
	return constant_MNG_COLORTYPE_G(name, len, arg);
    case 'I':
	if (strEQ(name + 7, "ORTYPE_INDEXED")) {	/* MNG_COL removed */
#ifdef MNG_COLORTYPE_INDEXED
	    return MNG_COLORTYPE_INDEXED;
#else
	    goto not_there;
#endif
	}
    case 'J':
	if (!strnEQ(name + 7,"ORTYPE_", 7))
	    break;
	return constant_MNG_COLORTYPE_J(name, len, arg);
    case 'R':
	if (!strnEQ(name + 7,"ORTYPE_", 7))
	    break;
	return constant_MNG_COLORTYPE_R(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_COMPO(char *name, int len, int arg)
{
    if (9 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 5]) {
    case 'O':
	if (strEQ(name + 9, "SITE_OVER")) {	/* MNG_COMPO removed */
#ifdef MNG_COMPOSITE_OVER
	    return MNG_COMPOSITE_OVER;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 9, "SITE_REPLACE")) {	/* MNG_COMPO removed */
#ifdef MNG_COMPOSITE_REPLACE
	    return MNG_COMPOSITE_REPLACE;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 9, "SITE_UNDER")) {	/* MNG_COMPO removed */
#ifdef MNG_COMPOSITE_UNDER
	    return MNG_COMPOSITE_UNDER;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_COMPR(char *name, int len, int arg)
{
    if (9 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 7]) {
    case 'B':
	if (strEQ(name + 9, "ESSION_BASELINEJPEG")) {	/* MNG_COMPR removed */
#ifdef MNG_COMPRESSION_BASELINEJPEG
	    return MNG_COMPRESSION_BASELINEJPEG;
#else
	    goto not_there;
#endif
	}
    case 'D':
	if (strEQ(name + 9, "ESSION_DEFLATE")) {	/* MNG_COMPR removed */
#ifdef MNG_COMPRESSION_DEFLATE
	    return MNG_COMPRESSION_DEFLATE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_COM(char *name, int len, int arg)
{
    if (7 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 1]) {
    case 'O':
	if (!strnEQ(name + 7,"P", 1))
	    break;
	return constant_MNG_COMPO(name, len, arg);
    case 'R':
	if (!strnEQ(name + 7,"P", 1))
	    break;
	return constant_MNG_COMPR(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CO(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'L':
	return constant_MNG_COL(name, len, arg);
    case 'M':
	return constant_MNG_COM(name, len, arg);
    case 'N':
	return constant_MNG_CON(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGESYNCID_N(char *name, int len, int arg)
{
    switch (name[18 + 0]) {
    case 'E':
	if (strEQ(name + 18, "EXTSUBFRAME")) {	/* MNG_CHANGESYNCID_N removed */
#ifdef MNG_CHANGESYNCID_NEXTSUBFRAME
	    return MNG_CHANGESYNCID_NEXTSUBFRAME;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 18, "O")) {	/* MNG_CHANGESYNCID_N removed */
#ifdef MNG_CHANGESYNCID_NO
	    return MNG_CHANGESYNCID_NO;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGES(char *name, int len, int arg)
{
    if (11 + 6 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 6]) {
    case 'D':
	if (strEQ(name + 11, "YNCID_DEFAULT")) {	/* MNG_CHANGES removed */
#ifdef MNG_CHANGESYNCID_DEFAULT
	    return MNG_CHANGESYNCID_DEFAULT;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (!strnEQ(name + 11,"YNCID_", 6))
	    break;
	return constant_MNG_CHANGESYNCID_N(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGECLIPPING_N(char *name, int len, int arg)
{
    switch (name[20 + 0]) {
    case 'E':
	if (strEQ(name + 20, "EXTSUBFRAME")) {	/* MNG_CHANGECLIPPING_N removed */
#ifdef MNG_CHANGECLIPPING_NEXTSUBFRAME
	    return MNG_CHANGECLIPPING_NEXTSUBFRAME;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 20, "O")) {	/* MNG_CHANGECLIPPING_N removed */
#ifdef MNG_CHANGECLIPPING_NO
	    return MNG_CHANGECLIPPING_NO;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGEC(char *name, int len, int arg)
{
    if (11 + 8 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 8]) {
    case 'D':
	if (strEQ(name + 11, "LIPPING_DEFAULT")) {	/* MNG_CHANGEC removed */
#ifdef MNG_CHANGECLIPPING_DEFAULT
	    return MNG_CHANGECLIPPING_DEFAULT;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (!strnEQ(name + 11,"LIPPING_", 8))
	    break;
	return constant_MNG_CHANGECLIPPING_N(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGETIMOUT_DEC(char *name, int len, int arg)
{
    if (20 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[20 + 5]) {
    case '1':
	if (strEQ(name + 20, "ODER_1")) {	/* MNG_CHANGETIMOUT_DEC removed */
#ifdef MNG_CHANGETIMOUT_DECODER_1
	    return MNG_CHANGETIMOUT_DECODER_1;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 20, "ODER_2")) {	/* MNG_CHANGETIMOUT_DEC removed */
#ifdef MNG_CHANGETIMOUT_DECODER_2
	    return MNG_CHANGETIMOUT_DECODER_2;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGETIMOUT_DET(char *name, int len, int arg)
{
    if (20 + 11 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[20 + 11]) {
    case '1':
	if (strEQ(name + 20, "ERMINISTIC_1")) {	/* MNG_CHANGETIMOUT_DET removed */
#ifdef MNG_CHANGETIMOUT_DETERMINISTIC_1
	    return MNG_CHANGETIMOUT_DETERMINISTIC_1;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 20, "ERMINISTIC_2")) {	/* MNG_CHANGETIMOUT_DET removed */
#ifdef MNG_CHANGETIMOUT_DETERMINISTIC_2
	    return MNG_CHANGETIMOUT_DETERMINISTIC_2;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGETIMOUT_D(char *name, int len, int arg)
{
    if (18 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[18 + 1]) {
    case 'C':
	if (!strnEQ(name + 18,"E", 1))
	    break;
	return constant_MNG_CHANGETIMOUT_DEC(name, len, arg);
    case 'T':
	if (!strnEQ(name + 18,"E", 1))
	    break;
	return constant_MNG_CHANGETIMOUT_DET(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGETIMOUT_U(char *name, int len, int arg)
{
    if (18 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[18 + 4]) {
    case '1':
	if (strEQ(name + 18, "SER_1")) {	/* MNG_CHANGETIMOUT_U removed */
#ifdef MNG_CHANGETIMOUT_USER_1
	    return MNG_CHANGETIMOUT_USER_1;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 18, "SER_2")) {	/* MNG_CHANGETIMOUT_U removed */
#ifdef MNG_CHANGETIMOUT_USER_2
	    return MNG_CHANGETIMOUT_USER_2;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGETIMOUT_E(char *name, int len, int arg)
{
    if (18 + 8 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[18 + 8]) {
    case '1':
	if (strEQ(name + 18, "XTERNAL_1")) {	/* MNG_CHANGETIMOUT_E removed */
#ifdef MNG_CHANGETIMOUT_EXTERNAL_1
	    return MNG_CHANGETIMOUT_EXTERNAL_1;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 18, "XTERNAL_2")) {	/* MNG_CHANGETIMOUT_E removed */
#ifdef MNG_CHANGETIMOUT_EXTERNAL_2
	    return MNG_CHANGETIMOUT_EXTERNAL_2;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGET(char *name, int len, int arg)
{
    if (11 + 6 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 6]) {
    case 'D':
	if (!strnEQ(name + 11,"IMOUT_", 6))
	    break;
	return constant_MNG_CHANGETIMOUT_D(name, len, arg);
    case 'E':
	if (!strnEQ(name + 11,"IMOUT_", 6))
	    break;
	return constant_MNG_CHANGETIMOUT_E(name, len, arg);
    case 'N':
	if (strEQ(name + 11, "IMOUT_NO")) {	/* MNG_CHANGET removed */
#ifdef MNG_CHANGETIMOUT_NO
	    return MNG_CHANGETIMOUT_NO;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (!strnEQ(name + 11,"IMOUT_", 6))
	    break;
	return constant_MNG_CHANGETIMOUT_U(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGEDELAY_N(char *name, int len, int arg)
{
    switch (name[17 + 0]) {
    case 'E':
	if (strEQ(name + 17, "EXTSUBFRAME")) {	/* MNG_CHANGEDELAY_N removed */
#ifdef MNG_CHANGEDELAY_NEXTSUBFRAME
	    return MNG_CHANGEDELAY_NEXTSUBFRAME;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 17, "O")) {	/* MNG_CHANGEDELAY_N removed */
#ifdef MNG_CHANGEDELAY_NO
	    return MNG_CHANGEDELAY_NO;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHANGED(char *name, int len, int arg)
{
    if (11 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 5]) {
    case 'D':
	if (strEQ(name + 11, "ELAY_DEFAULT")) {	/* MNG_CHANGED removed */
#ifdef MNG_CHANGEDELAY_DEFAULT
	    return MNG_CHANGEDELAY_DEFAULT;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (!strnEQ(name + 11,"ELAY_", 5))
	    break;
	return constant_MNG_CHANGEDELAY_N(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CHA(char *name, int len, int arg)
{
    if (7 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 3]) {
    case 'C':
	if (!strnEQ(name + 7,"NGE", 3))
	    break;
	return constant_MNG_CHANGEC(name, len, arg);
    case 'D':
	if (!strnEQ(name + 7,"NGE", 3))
	    break;
	return constant_MNG_CHANGED(name, len, arg);
    case 'S':
	if (!strnEQ(name + 7,"NGE", 3))
	    break;
	return constant_MNG_CHANGES(name, len, arg);
    case 'T':
	if (!strnEQ(name + 7,"NGE", 3))
	    break;
	return constant_MNG_CHANGET(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CH(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'A':
	return constant_MNG_CHA(name, len, arg);
    case 'E':
	if (strEQ(name + 6, "ECK_BAD_ICCP")) {	/* MNG_CH removed */
#ifdef MNG_CHECK_BAD_ICCP
	    return 1; // MNG_CHECK_BAD_ICCP;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 6, "UNKNOTALLOWED")) {	/* MNG_CH removed */
#ifdef MNG_CHUNKNOTALLOWED
	    return MNG_CHUNKNOTALLOWED;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_GRAYA(char *name, int len, int arg)
{
    switch (name[16 + 0]) {
    case '1':
	if (strEQ(name + 16, "16")) {	/* MNG_CANVAS_GRAYA removed */
#ifdef MNG_CANVAS_GRAYA16
	    return MNG_CANVAS_GRAYA16;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (strEQ(name + 16, "8")) {	/* MNG_CANVAS_GRAYA removed */
#ifdef MNG_CANVAS_GRAYA8
	    return MNG_CANVAS_GRAYA8;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_G(char *name, int len, int arg)
{
    if (12 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 3]) {
    case '1':
	if (strEQ(name + 12, "RAY16")) {	/* MNG_CANVAS_G removed */
#ifdef MNG_CANVAS_GRAY16
	    return MNG_CANVAS_GRAY16;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (strEQ(name + 12, "RAY8")) {	/* MNG_CANVAS_G removed */
#ifdef MNG_CANVAS_GRAY8
	    return MNG_CANVAS_GRAY8;
#else
	    goto not_there;
#endif
	}
    case 'A':
	if (!strnEQ(name + 12,"RAY", 3))
	    break;
	return constant_MNG_CANVAS_GRAYA(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_AG(char *name, int len, int arg)
{
    if (13 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[13 + 3]) {
    case '1':
	if (strEQ(name + 13, "RAY16")) {	/* MNG_CANVAS_AG removed */
#ifdef MNG_CANVAS_AGRAY16
	    return MNG_CANVAS_AGRAY16;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (strEQ(name + 13, "RAY8")) {	/* MNG_CANVAS_AG removed */
#ifdef MNG_CANVAS_AGRAY8
	    return MNG_CANVAS_AGRAY8;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_AR(char *name, int len, int arg)
{
    if (13 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[13 + 2]) {
    case '1':
	if (strEQ(name + 13, "GB16")) {	/* MNG_CANVAS_AR removed */
#ifdef MNG_CANVAS_ARGB16
	    return MNG_CANVAS_ARGB16;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (strEQ(name + 13, "GB8")) {	/* MNG_CANVAS_AR removed */
#ifdef MNG_CANVAS_ARGB8
	    return MNG_CANVAS_ARGB8;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_AB(char *name, int len, int arg)
{
    if (13 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[13 + 2]) {
    case '1':
	if (strEQ(name + 13, "GR16")) {	/* MNG_CANVAS_AB removed */
#ifdef MNG_CANVAS_ABGR16
	    return MNG_CANVAS_ABGR16;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (strEQ(name + 13, "GR8")) {	/* MNG_CANVAS_AB removed */
#ifdef MNG_CANVAS_ABGR8
	    return MNG_CANVAS_ABGR8;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_A(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case 'B':
	return constant_MNG_CANVAS_AB(name, len, arg);
    case 'G':
	return constant_MNG_CANVAS_AG(name, len, arg);
    case 'R':
	return constant_MNG_CANVAS_AR(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_RGB8(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case '\0':
	if (strEQ(name + 15, "")) {	/* MNG_CANVAS_RGB8 removed */
#ifdef MNG_CANVAS_RGB8
	    return MNG_CANVAS_RGB8;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 15, "_A8")) {	/* MNG_CANVAS_RGB8 removed */
#ifdef MNG_CANVAS_RGB8_A8
	    return MNG_CANVAS_RGB8_A8;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_RGBA(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case '1':
	if (strEQ(name + 15, "16")) {	/* MNG_CANVAS_RGBA removed */
#ifdef MNG_CANVAS_RGBA16
	    return MNG_CANVAS_RGBA16;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (strEQ(name + 15, "8")) {	/* MNG_CANVAS_RGBA removed */
#ifdef MNG_CANVAS_RGBA8
	    return MNG_CANVAS_RGBA8;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_R(char *name, int len, int arg)
{
    if (12 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 2]) {
    case '1':
	if (strEQ(name + 12, "GB16")) {	/* MNG_CANVAS_R removed */
#ifdef MNG_CANVAS_RGB16
	    return MNG_CANVAS_RGB16;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (!strnEQ(name + 12,"GB", 2))
	    break;
	return constant_MNG_CANVAS_RGB8(name, len, arg);
    case 'A':
	if (!strnEQ(name + 12,"GB", 2))
	    break;
	return constant_MNG_CANVAS_RGBA(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_BGRA8(char *name, int len, int arg)
{
    switch (name[16 + 0]) {
    case '\0':
	if (strEQ(name + 16, "")) {	/* MNG_CANVAS_BGRA8 removed */
#ifdef MNG_CANVAS_BGRA8
	    return MNG_CANVAS_BGRA8;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 16, "PM")) {	/* MNG_CANVAS_BGRA8 removed */
#ifdef MNG_CANVAS_BGRA8PM
	    return MNG_CANVAS_BGRA8PM;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_BGRA(char *name, int len, int arg)
{
    switch (name[15 + 0]) {
    case '1':
	if (strEQ(name + 15, "16")) {	/* MNG_CANVAS_BGRA removed */
#ifdef MNG_CANVAS_BGRA16
	    return MNG_CANVAS_BGRA16;
#else
	    goto not_there;
#endif
	}
    case '8':
	return constant_MNG_CANVAS_BGRA8(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_B(char *name, int len, int arg)
{
    if (12 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 2]) {
    case '1':
	if (strEQ(name + 12, "GR16")) {	/* MNG_CANVAS_B removed */
#ifdef MNG_CANVAS_BGR16
	    return MNG_CANVAS_BGR16;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (strEQ(name + 12, "GR8")) {	/* MNG_CANVAS_B removed */
#ifdef MNG_CANVAS_BGR8
	    return MNG_CANVAS_BGR8;
#else
	    goto not_there;
#endif
	}
    case 'A':
	if (!strnEQ(name + 12,"GR", 2))
	    break;
	return constant_MNG_CANVAS_BGRA(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANVAS_D(char *name, int len, int arg)
{
    if (12 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 2]) {
    case '5':
	if (strEQ(name + 12, "X15")) {	/* MNG_CANVAS_D removed */
#ifdef MNG_CANVAS_DX15
	    return MNG_CANVAS_DX15;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 12, "X16")) {	/* MNG_CANVAS_D removed */
#ifdef MNG_CANVAS_DX16
	    return MNG_CANVAS_DX16;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CANV(char *name, int len, int arg)
{
    if (8 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case 'A':
	if (!strnEQ(name + 8,"AS_", 3))
	    break;
	return constant_MNG_CANVAS_A(name, len, arg);
    case 'B':
	if (!strnEQ(name + 8,"AS_", 3))
	    break;
	return constant_MNG_CANVAS_B(name, len, arg);
    case 'D':
	if (!strnEQ(name + 8,"AS_", 3))
	    break;
	return constant_MNG_CANVAS_D(name, len, arg);
    case 'G':
	if (!strnEQ(name + 8,"AS_", 3))
	    break;
	return constant_MNG_CANVAS_G(name, len, arg);
    case 'R':
	if (!strnEQ(name + 8,"AS_", 3))
	    break;
	return constant_MNG_CANVAS_R(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CA(char *name, int len, int arg)
{
    if (6 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'N':
	if (strEQ(name + 6, "NNOTBEEMPTY")) {	/* MNG_CA removed */
#ifdef MNG_CANNOTBEEMPTY
	    return MNG_CANNOTBEEMPTY;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (!strnEQ(name + 6,"N", 1))
	    break;
	return constant_MNG_CANV(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_CL(char *name, int len, int arg)
{
    if (6 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 7]) {
    case 'A':
	if (strEQ(name + 6, "IPPING_ABSOLUTE")) {	/* MNG_CL removed */
#ifdef MNG_CLIPPING_ABSOLUTE
	    return MNG_CLIPPING_ABSOLUTE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 6, "IPPING_RELATIVE")) {	/* MNG_CL removed */
#ifdef MNG_CLIPPING_RELATIVE
	    return MNG_CLIPPING_RELATIVE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_C(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	return constant_MNG_CA(name, len, arg);
    case 'H':
	return constant_MNG_CH(name, len, arg);
    case 'L':
	return constant_MNG_CL(name, len, arg);
    case 'O':
	return constant_MNG_CO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TO(char *name, int len, int arg)
{
    if (6 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 5]) {
    case 'I':
	if (strEQ(name + 6, "OMUCHIDAT")) {	/* MNG_TO removed */
#ifdef MNG_TOOMUCHIDAT
	    return MNG_TOOMUCHIDAT;
#else
	    goto not_there;
#endif
	}
    case 'J':
	if (strEQ(name + 6, "OMUCHJDAT")) {	/* MNG_TO removed */
#ifdef MNG_TOOMUCHJDAT
	    return MNG_TOOMUCHJDAT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TY(char *name, int len, int arg)
{
    if (6 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case 'I':
	if (strEQ(name + 6, "PE_ITXT")) {	/* MNG_TY removed */
#ifdef MNG_TYPE_ITXT
	    return MNG_TYPE_ITXT;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 6, "PE_TEXT")) {	/* MNG_TY removed */
#ifdef MNG_TYPE_TEXT
	    return MNG_TYPE_TEXT;
#else
	    goto not_there;
#endif
	}
    case 'Z':
	if (strEQ(name + 6, "PE_ZTXT")) {	/* MNG_TY removed */
#ifdef MNG_TYPE_ZTXT
	    return MNG_TYPE_ZTXT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TARGET_R(char *name, int len, int arg)
{
    if (12 + 8 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 8]) {
    case 'P':
	if (strEQ(name + 12, "ELATIVE_PREVPAST")) {	/* MNG_TARGET_R removed */
#ifdef MNG_TARGET_RELATIVE_PREVPAST
	    return MNG_TARGET_RELATIVE_PREVPAST;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 12, "ELATIVE_SAMEPAST")) {	/* MNG_TARGET_R removed */
#ifdef MNG_TARGET_RELATIVE_SAMEPAST
	    return MNG_TARGET_RELATIVE_SAMEPAST;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TARGET_(char *name, int len, int arg)
{
    switch (name[11 + 0]) {
    case 'A':
	if (strEQ(name + 11, "ABSOLUTE")) {	/* MNG_TARGET_ removed */
#ifdef MNG_TARGET_ABSOLUTE
	    return MNG_TARGET_ABSOLUTE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	return constant_MNG_TARGET_R(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TA(char *name, int len, int arg)
{
    if (6 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 4]) {
    case 'N':
	if (strEQ(name + 6, "RGETNOALPHA")) {	/* MNG_TA removed */
#ifdef MNG_TARGETNOALPHA
	    return MNG_TARGETNOALPHA;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 6,"RGET", 4))
	    break;
	return constant_MNG_TARGET_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TR(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'A':
	if (strEQ(name + 6, "ACE_TELLTALE")) {	/* MNG_TR removed */
#ifdef MNG_TRACE_TELLTALE
	    return 1; // MNG_TRACE_TELLTALE;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 6, "UE")) {	/* MNG_TR removed */
#ifdef MNG_TRUE
	    return MNG_TRUE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TERMINATION_DEC(char *name, int len, int arg)
{
    if (19 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 5]) {
    case 'C':
	if (strEQ(name + 19, "ODER_C")) {	/* MNG_TERMINATION_DEC removed */
#ifdef MNG_TERMINATION_DECODER_C
	    return MNG_TERMINATION_DECODER_C;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 19, "ODER_NC")) {	/* MNG_TERMINATION_DEC removed */
#ifdef MNG_TERMINATION_DECODER_NC
	    return MNG_TERMINATION_DECODER_NC;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TERMINATION_DET(char *name, int len, int arg)
{
    if (19 + 11 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[19 + 11]) {
    case 'C':
	if (strEQ(name + 19, "ERMINISTIC_C")) {	/* MNG_TERMINATION_DET removed */
#ifdef MNG_TERMINATION_DETERMINISTIC_C
	    return MNG_TERMINATION_DETERMINISTIC_C;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 19, "ERMINISTIC_NC")) {	/* MNG_TERMINATION_DET removed */
#ifdef MNG_TERMINATION_DETERMINISTIC_NC
	    return MNG_TERMINATION_DETERMINISTIC_NC;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TERMINATION_D(char *name, int len, int arg)
{
    if (17 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 1]) {
    case 'C':
	if (!strnEQ(name + 17,"E", 1))
	    break;
	return constant_MNG_TERMINATION_DEC(name, len, arg);
    case 'T':
	if (!strnEQ(name + 17,"E", 1))
	    break;
	return constant_MNG_TERMINATION_DET(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TERMINATION_U(char *name, int len, int arg)
{
    if (17 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 4]) {
    case 'C':
	if (strEQ(name + 17, "SER_C")) {	/* MNG_TERMINATION_U removed */
#ifdef MNG_TERMINATION_USER_C
	    return MNG_TERMINATION_USER_C;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 17, "SER_NC")) {	/* MNG_TERMINATION_U removed */
#ifdef MNG_TERMINATION_USER_NC
	    return MNG_TERMINATION_USER_NC;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TERMINATION_E(char *name, int len, int arg)
{
    if (17 + 8 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[17 + 8]) {
    case 'C':
	if (strEQ(name + 17, "XTERNAL_C")) {	/* MNG_TERMINATION_E removed */
#ifdef MNG_TERMINATION_EXTERNAL_C
	    return MNG_TERMINATION_EXTERNAL_C;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 17, "XTERNAL_NC")) {	/* MNG_TERMINATION_E removed */
#ifdef MNG_TERMINATION_EXTERNAL_NC
	    return MNG_TERMINATION_EXTERNAL_NC;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TERMI(char *name, int len, int arg)
{
    if (9 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 7]) {
    case 'D':
	if (!strnEQ(name + 9,"NATION_", 7))
	    break;
	return constant_MNG_TERMINATION_D(name, len, arg);
    case 'E':
	if (!strnEQ(name + 9,"NATION_", 7))
	    break;
	return constant_MNG_TERMINATION_E(name, len, arg);
    case 'U':
	if (!strnEQ(name + 9,"NATION_", 7))
	    break;
	return constant_MNG_TERMINATION_U(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TERMA(char *name, int len, int arg)
{
    if (9 + 6 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 6]) {
    case 'C':
	if (strEQ(name + 9, "CTION_CLEAR")) {	/* MNG_TERMA removed */
#ifdef MNG_TERMACTION_CLEAR
	    return MNG_TERMACTION_CLEAR;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 9, "CTION_FIRSTFRAME")) {	/* MNG_TERMA removed */
#ifdef MNG_TERMACTION_FIRSTFRAME
	    return MNG_TERMACTION_FIRSTFRAME;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 9, "CTION_LASTFRAME")) {	/* MNG_TERMA removed */
#ifdef MNG_TERMACTION_LASTFRAME
	    return MNG_TERMACTION_LASTFRAME;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 9, "CTION_REPEAT")) {	/* MNG_TERMA removed */
#ifdef MNG_TERMACTION_REPEAT
	    return MNG_TERMACTION_REPEAT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_TE(char *name, int len, int arg)
{
    if (6 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 2]) {
    case 'A':
	if (!strnEQ(name + 6,"RM", 2))
	    break;
	return constant_MNG_TERMA(name, len, arg);
    case 'I':
	if (!strnEQ(name + 6,"RM", 2))
	    break;
	return constant_MNG_TERMI(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_T(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	return constant_MNG_TA(name, len, arg);
    case 'E':
	return constant_MNG_TE(name, len, arg);
    case 'O':
	return constant_MNG_TO(name, len, arg);
    case 'R':
	return constant_MNG_TR(name, len, arg);
    case 'Y':
	return constant_MNG_TY(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DO(char *name, int len, int arg)
{
    if (6 + 8 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 8]) {
    case 'N':
	if (strEQ(name + 6, "NOTSHOW_NOTVISIBLE")) {	/* MNG_DO removed */
#ifdef MNG_DONOTSHOW_NOTVISIBLE
	    return MNG_DONOTSHOW_NOTVISIBLE;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 6, "NOTSHOW_VISIBLE")) {	/* MNG_DO removed */
#ifdef MNG_DONOTSHOW_VISIBLE
	    return MNG_DONOTSHOW_VISIBLE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DL(char *name, int len, int arg)
{
    if (6 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case '\0':
	if (strEQ(name + 6, "L")) {	/* MNG_DL removed */
#ifdef MNG_DLL
	    return 1; // MNG_DLL;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 6, "LNOTLOADED")) {	/* MNG_DL removed */
#ifdef MNG_DLLNOTLOADED
	    return MNG_DLLNOTLOADED;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DELTATYPE_REPLACER(char *name, int len, int arg)
{
    if (22 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[22 + 2]) {
    case '\0':
	if (strEQ(name + 22, "GB")) {	/* MNG_DELTATYPE_REPLACER removed */
#ifdef MNG_DELTATYPE_REPLACERGB
	    return MNG_DELTATYPE_REPLACERGB;
#else
	    goto not_there;
#endif
	}
    case 'A':
	if (strEQ(name + 22, "GBA")) {	/* MNG_DELTATYPE_REPLACER removed */
#ifdef MNG_DELTATYPE_REPLACERGBA
	    return MNG_DELTATYPE_REPLACERGBA;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DELTATYPE_R(char *name, int len, int arg)
{
    if (15 + 6 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 6]) {
    case '\0':
	if (strEQ(name + 15, "EPLACE")) {	/* MNG_DELTATYPE_R removed */
#ifdef MNG_DELTATYPE_REPLACE
	    return MNG_DELTATYPE_REPLACE;
#else
	    goto not_there;
#endif
	}
    case 'A':
	if (strEQ(name + 15, "EPLACEALPHA")) {	/* MNG_DELTATYPE_R removed */
#ifdef MNG_DELTATYPE_REPLACEALPHA
	    return MNG_DELTATYPE_REPLACEALPHA;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (!strnEQ(name + 15,"EPLACE", 6))
	    break;
	return constant_MNG_DELTATYPE_REPLACER(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DELTATYPE_BLOCKP(char *name, int len, int arg)
{
    if (20 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[20 + 4]) {
    case 'A':
	if (strEQ(name + 20, "IXELADD")) {	/* MNG_DELTATYPE_BLOCKP removed */
#ifdef MNG_DELTATYPE_BLOCKPIXELADD
	    return MNG_DELTATYPE_BLOCKPIXELADD;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 20, "IXELREPLACE")) {	/* MNG_DELTATYPE_BLOCKP removed */
#ifdef MNG_DELTATYPE_BLOCKPIXELREPLACE
	    return MNG_DELTATYPE_BLOCKPIXELREPLACE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DELTATYPE_BLOCKA(char *name, int len, int arg)
{
    if (20 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[20 + 4]) {
    case 'A':
	if (strEQ(name + 20, "LPHAADD")) {	/* MNG_DELTATYPE_BLOCKA removed */
#ifdef MNG_DELTATYPE_BLOCKALPHAADD
	    return MNG_DELTATYPE_BLOCKALPHAADD;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 20, "LPHAREPLACE")) {	/* MNG_DELTATYPE_BLOCKA removed */
#ifdef MNG_DELTATYPE_BLOCKALPHAREPLACE
	    return MNG_DELTATYPE_BLOCKALPHAREPLACE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DELTATYPE_BLOCKC(char *name, int len, int arg)
{
    if (20 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[20 + 4]) {
    case 'A':
	if (strEQ(name + 20, "OLORADD")) {	/* MNG_DELTATYPE_BLOCKC removed */
#ifdef MNG_DELTATYPE_BLOCKCOLORADD
	    return MNG_DELTATYPE_BLOCKCOLORADD;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 20, "OLORREPLACE")) {	/* MNG_DELTATYPE_BLOCKC removed */
#ifdef MNG_DELTATYPE_BLOCKCOLORREPLACE
	    return MNG_DELTATYPE_BLOCKCOLORREPLACE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DELTATYPE_B(char *name, int len, int arg)
{
    if (15 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 4]) {
    case 'A':
	if (!strnEQ(name + 15,"LOCK", 4))
	    break;
	return constant_MNG_DELTATYPE_BLOCKA(name, len, arg);
    case 'C':
	if (!strnEQ(name + 15,"LOCK", 4))
	    break;
	return constant_MNG_DELTATYPE_BLOCKC(name, len, arg);
    case 'P':
	if (!strnEQ(name + 15,"LOCK", 4))
	    break;
	return constant_MNG_DELTATYPE_BLOCKP(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DELTATYPE_DELTAR(char *name, int len, int arg)
{
    if (20 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[20 + 2]) {
    case '\0':
	if (strEQ(name + 20, "GB")) {	/* MNG_DELTATYPE_DELTAR removed */
#ifdef MNG_DELTATYPE_DELTARGB
	    return MNG_DELTATYPE_DELTARGB;
#else
	    goto not_there;
#endif
	}
    case 'A':
	if (strEQ(name + 20, "GBA")) {	/* MNG_DELTATYPE_DELTAR removed */
#ifdef MNG_DELTATYPE_DELTARGBA
	    return MNG_DELTATYPE_DELTARGBA;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DELTATYPE_D(char *name, int len, int arg)
{
    if (15 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[15 + 4]) {
    case 'A':
	if (strEQ(name + 15, "ELTAALPHA")) {	/* MNG_DELTATYPE_D removed */
#ifdef MNG_DELTATYPE_DELTAALPHA
	    return MNG_DELTATYPE_DELTAALPHA;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (!strnEQ(name + 15,"ELTA", 4))
	    break;
	return constant_MNG_DELTATYPE_DELTAR(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DEL(char *name, int len, int arg)
{
    if (7 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 7]) {
    case 'B':
	if (!strnEQ(name + 7,"TATYPE_", 7))
	    break;
	return constant_MNG_DELTATYPE_B(name, len, arg);
    case 'D':
	if (!strnEQ(name + 7,"TATYPE_", 7))
	    break;
	return constant_MNG_DELTATYPE_D(name, len, arg);
    case 'N':
	if (strEQ(name + 7, "TATYPE_NOCHANGE")) {	/* MNG_DEL removed */
#ifdef MNG_DELTATYPE_NOCHANGE
	    return MNG_DELTATYPE_NOCHANGE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (!strnEQ(name + 7,"TATYPE_", 7))
	    break;
	return constant_MNG_DELTATYPE_R(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_DE(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'C':
	if (strEQ(name + 6, "CL")) {	/* MNG_DE removed */
#ifdef MNG_DECL
	    return 1; // MNG_DECL;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'L':
	return constant_MNG_DEL(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_D(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'E':
	return constant_MNG_DE(name, len, arg);
    case 'L':
	return constant_MNG_DL(name, len, arg);
    case 'O':
	return constant_MNG_DO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UNI(char *name, int len, int arg)
{
    if (7 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 2]) {
    case 'M':
	if (strEQ(name + 7, "T_METER")) {	/* MNG_UNI removed */
#ifdef MNG_UNIT_METER
	    return MNG_UNIT_METER;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 7, "T_UNKNOWN")) {	/* MNG_UNI removed */
#ifdef MNG_UNIT_UNKNOWN
	    return MNG_UNIT_UNKNOWN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UN(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'E':
	if (strEQ(name + 6, "EXPECTEDEOF")) {	/* MNG_UN removed */
#ifdef MNG_UNEXPECTEDEOF
	    return MNG_UNEXPECTEDEOF;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant_MNG_UNI(name, len, arg);
    case 'K':
	if (strEQ(name + 6, "KNOWNCRITICAL")) {	/* MNG_UN removed */
#ifdef MNG_UNKNOWNCRITICAL
	    return MNG_UNKNOWNCRITICAL;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 6, "SUPPORTEDNEED")) {	/* MNG_UN removed */
#ifdef MNG_UNSUPPORTEDNEED
	    return MNG_UNSUPPORTEDNEED;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_B(char *name, int len, int arg)
{
    if (10 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 1]) {
    case 'C':
	if (strEQ(name + 10, "ACK")) {	/* MNG_UINT_B removed */
#ifdef MNG_UINT_BACK
	    return MNG_UINT_BACK;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 10, "ASI")) {	/* MNG_UINT_B removed */
#ifdef MNG_UINT_BASI
	    return MNG_UINT_BASI;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_C(char *name, int len, int arg)
{
    if (10 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 1]) {
    case 'I':
	if (strEQ(name + 10, "LIP")) {	/* MNG_UINT_C removed */
#ifdef MNG_UINT_CLIP
	    return MNG_UINT_CLIP;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 10, "LON")) {	/* MNG_UINT_C removed */
#ifdef MNG_UINT_CLON
	    return MNG_UINT_CLON;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_D(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'B':
	if (strEQ(name + 10, "BYK")) {	/* MNG_UINT_D removed */
#ifdef MNG_UINT_DBYK
	    return MNG_UINT_DBYK;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 10, "EFI")) {	/* MNG_UINT_D removed */
#ifdef MNG_UINT_DEFI
	    return MNG_UINT_DEFI;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 10, "HDR")) {	/* MNG_UINT_D removed */
#ifdef MNG_UINT_DHDR
	    return MNG_UINT_DHDR;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 10, "ISC")) {	/* MNG_UINT_D removed */
#ifdef MNG_UINT_DISC
	    return MNG_UINT_DISC;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 10, "ROP")) {	/* MNG_UINT_D removed */
#ifdef MNG_UINT_DROP
	    return MNG_UINT_DROP;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_I(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'D':
	if (strEQ(name + 10, "DAT")) {	/* MNG_UINT_I removed */
#ifdef MNG_UINT_IDAT
	    return MNG_UINT_IDAT;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 10, "END")) {	/* MNG_UINT_I removed */
#ifdef MNG_UINT_IEND
	    return MNG_UINT_IEND;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 10, "HDR")) {	/* MNG_UINT_I removed */
#ifdef MNG_UINT_IHDR
	    return MNG_UINT_IHDR;
#else
	    goto not_there;
#endif
	}
    case 'J':
	if (strEQ(name + 10, "JNG")) {	/* MNG_UINT_I removed */
#ifdef MNG_UINT_IJNG
	    return MNG_UINT_IJNG;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 10, "PNG")) {	/* MNG_UINT_I removed */
#ifdef MNG_UINT_IPNG
	    return MNG_UINT_IPNG;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_i(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'C':
	if (strEQ(name + 10, "CCP")) {	/* MNG_UINT_i removed */
#ifdef MNG_UINT_iCCP
	    return MNG_UINT_iCCP;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 10, "TXt")) {	/* MNG_UINT_i removed */
#ifdef MNG_UINT_iTXt
	    return MNG_UINT_iTXt;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_JD(char *name, int len, int arg)
{
    if (11 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 1]) {
    case 'A':
	if (strEQ(name + 11, "AA")) {	/* MNG_UINT_JD removed */
#ifdef MNG_UINT_JDAA
	    return MNG_UINT_JDAA;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 11, "AT")) {	/* MNG_UINT_JD removed */
#ifdef MNG_UINT_JDAT
	    return MNG_UINT_JDAT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_J(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'D':
	return constant_MNG_UINT_JD(name, len, arg);
    case 'H':
	if (strEQ(name + 10, "HDR")) {	/* MNG_UINT_J removed */
#ifdef MNG_UINT_JHDR
	    return MNG_UINT_JHDR;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 10, "SEP")) {	/* MNG_UINT_J removed */
#ifdef MNG_UINT_JSEP
	    return MNG_UINT_JSEP;
#else
	    goto not_there;
#endif
	}
    case 'd':
	if (strEQ(name + 10, "dAA")) {	/* MNG_UINT_J removed */
#ifdef MNG_UINT_JdAA
	    return MNG_UINT_JdAA;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_M(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'A':
	if (strEQ(name + 10, "AGN")) {	/* MNG_UINT_M removed */
#ifdef MNG_UINT_MAGN
	    return MNG_UINT_MAGN;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 10, "END")) {	/* MNG_UINT_M removed */
#ifdef MNG_UINT_MEND
	    return MNG_UINT_MEND;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 10, "HDR")) {	/* MNG_UINT_M removed */
#ifdef MNG_UINT_MHDR
	    return MNG_UINT_MHDR;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 10, "OVE")) {	/* MNG_UINT_M removed */
#ifdef MNG_UINT_MOVE
	    return MNG_UINT_MOVE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_P(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'A':
	if (strEQ(name + 10, "AST")) {	/* MNG_UINT_P removed */
#ifdef MNG_UINT_PAST
	    return MNG_UINT_PAST;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 10, "LTE")) {	/* MNG_UINT_P removed */
#ifdef MNG_UINT_PLTE
	    return MNG_UINT_PLTE;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 10, "PLT")) {	/* MNG_UINT_P removed */
#ifdef MNG_UINT_PPLT
	    return MNG_UINT_PPLT;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 10, "ROM")) {	/* MNG_UINT_P removed */
#ifdef MNG_UINT_PROM
	    return MNG_UINT_PROM;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_pH(char *name, int len, int arg)
{
    if (11 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 1]) {
    case 'g':
	if (strEQ(name + 11, "Yg")) {	/* MNG_UINT_pH removed */
#ifdef MNG_UINT_pHYg
	    return MNG_UINT_pHYg;
#else
	    goto not_there;
#endif
	}
    case 's':
	if (strEQ(name + 11, "Ys")) {	/* MNG_UINT_pH removed */
#ifdef MNG_UINT_pHYs
	    return MNG_UINT_pHYs;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_p(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'C':
	if (strEQ(name + 10, "CAL")) {	/* MNG_UINT_p removed */
#ifdef MNG_UINT_pCAL
	    return MNG_UINT_pCAL;
#else
	    goto not_there;
#endif
	}
    case 'H':
	return constant_MNG_UINT_pH(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_S(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'A':
	if (strEQ(name + 10, "AVE")) {	/* MNG_UINT_S removed */
#ifdef MNG_UINT_SAVE
	    return MNG_UINT_SAVE;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 10, "EEK")) {	/* MNG_UINT_S removed */
#ifdef MNG_UINT_SEEK
	    return MNG_UINT_SEEK;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 10, "HOW")) {	/* MNG_UINT_S removed */
#ifdef MNG_UINT_SHOW
	    return MNG_UINT_SHOW;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_s(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'B':
	if (strEQ(name + 10, "BIT")) {	/* MNG_UINT_s removed */
#ifdef MNG_UINT_sBIT
	    return MNG_UINT_sBIT;
#else
	    goto not_there;
#endif
	}
    case 'C':
	if (strEQ(name + 10, "CAL")) {	/* MNG_UINT_s removed */
#ifdef MNG_UINT_sCAL
	    return MNG_UINT_sCAL;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 10, "PLT")) {	/* MNG_UINT_s removed */
#ifdef MNG_UINT_sPLT
	    return MNG_UINT_sPLT;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 10, "RGB")) {	/* MNG_UINT_s removed */
#ifdef MNG_UINT_sRGB
	    return MNG_UINT_sRGB;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UINT_t(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'E':
	if (strEQ(name + 10, "EXt")) {	/* MNG_UINT_t removed */
#ifdef MNG_UINT_tEXt
	    return MNG_UINT_tEXt;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 10, "IME")) {	/* MNG_UINT_t removed */
#ifdef MNG_UINT_tIME
	    return MNG_UINT_tIME;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 10, "RNS")) {	/* MNG_UINT_t removed */
#ifdef MNG_UINT_tRNS
	    return MNG_UINT_tRNS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_UI(char *name, int len, int arg)
{
    if (6 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case 'B':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_B(name, len, arg);
    case 'C':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_C(name, len, arg);
    case 'D':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_D(name, len, arg);
    case 'E':
	if (strEQ(name + 6, "NT_ENDL")) {	/* MNG_UI removed */
#ifdef MNG_UINT_ENDL
	    return MNG_UINT_ENDL;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 6, "NT_FRAM")) {	/* MNG_UI removed */
#ifdef MNG_UINT_FRAM
	    return MNG_UINT_FRAM;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 6, "NT_HUH")) {	/* MNG_UI removed */
#ifdef MNG_UINT_HUH
	    return MNG_UINT_HUH;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_I(name, len, arg);
    case 'J':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_J(name, len, arg);
    case 'L':
	if (strEQ(name + 6, "NT_LOOP")) {	/* MNG_UI removed */
#ifdef MNG_UINT_LOOP
	    return MNG_UINT_LOOP;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_M(name, len, arg);
    case 'O':
	if (strEQ(name + 6, "NT_ORDR")) {	/* MNG_UI removed */
#ifdef MNG_UINT_ORDR
	    return MNG_UINT_ORDR;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_P(name, len, arg);
    case 'S':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_S(name, len, arg);
    case 'T':
	if (strEQ(name + 6, "NT_TERM")) {	/* MNG_UI removed */
#ifdef MNG_UINT_TERM
	    return MNG_UINT_TERM;
#else
	    goto not_there;
#endif
   }
    case 'U':
	if (strEQ(name + 6, "NT_UNKN")) {	/* MNG_UI removed */
#ifndef MNG_UINT_UNKN
#define MNG_UINT_UNKN 0x554e4b4eL
#endif
	    return MNG_UINT_UNKN;
	}
    case 'b':
	if (strEQ(name + 6, "NT_bKGD")) {	/* MNG_UI removed */
#ifdef MNG_UINT_bKGD
	    return MNG_UINT_bKGD;
#else
	    goto not_there;
#endif
	}
    case 'c':
	if (strEQ(name + 6, "NT_cHRM")) {	/* MNG_UI removed */
#ifdef MNG_UINT_cHRM
	    return MNG_UINT_cHRM;
#else
	    goto not_there;
#endif
	}
    case 'e':
	if (strEQ(name + 6, "NT_eXPI")) {	/* MNG_UI removed */
#ifdef MNG_UINT_eXPI
	    return MNG_UINT_eXPI;
#else
	    goto not_there;
#endif
	}
    case 'f':
	if (strEQ(name + 6, "NT_fPRI")) {	/* MNG_UI removed */
#ifdef MNG_UINT_fPRI
	    return MNG_UINT_fPRI;
#else
	    goto not_there;
#endif
	}
    case 'g':
	if (strEQ(name + 6, "NT_gAMA")) {	/* MNG_UI removed */
#ifdef MNG_UINT_gAMA
	    return MNG_UINT_gAMA;
#else
	    goto not_there;
#endif
	}
    case 'h':
	if (strEQ(name + 6, "NT_hIST")) {	/* MNG_UI removed */
#ifdef MNG_UINT_hIST
	    return MNG_UINT_hIST;
#else
	    goto not_there;
#endif
	}
    case 'i':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_i(name, len, arg);
    case 'n':
	if (strEQ(name + 6, "NT_nEED")) {	/* MNG_UI removed */
#ifdef MNG_UINT_nEED
	    return MNG_UINT_nEED;
#else
	    goto not_there;
#endif
	}
    case 'o':
	if (strEQ(name + 6, "NT_oFFs")) {	/* MNG_UI removed */
#ifdef MNG_UINT_oFFs
	    return MNG_UINT_oFFs;
#else
	    goto not_there;
#endif
	}
    case 'p':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_p(name, len, arg);
    case 's':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_s(name, len, arg);
    case 't':
	if (!strnEQ(name + 6,"NT_", 3))
	    break;
	return constant_MNG_UINT_t(name, len, arg);
    case 'z':
	if (strEQ(name + 6, "NT_zTXt")) {	/* MNG_UI removed */
#ifdef MNG_UINT_zTXt
	    return MNG_UINT_zTXt;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_U(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'I':
	return constant_MNG_UI(name, len, arg);
    case 'N':
	return constant_MNG_UN(name, len, arg);
    case 'S':
	if (strEQ(name + 5, "SE_SETJMP")) {	/* MNG_U removed */
#ifdef MNG_USE_SETJMP
	    return 1; // MNG_USE_SETJMP;
#else
	    return 0; // goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_E(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'N':
	if (strEQ(name + 5, "NDWITHNULL")) {	/* MNG_E removed */
#ifdef MNG_ENDWITHNULL
	    return MNG_ENDWITHNULL;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 5, "RROR_TELLTALE")) {	/* MNG_E removed */
#ifdef MNG_ERROR_TELLTALE
	    return 1; // MNG_ERROR_TELLTALE;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'X':
	if (strEQ(name + 5, "XT")) {	/* MNG_E removed */
#ifdef MNG_EXT
	    return 1; // MNG_EXT;
#else
	    return 0; // goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_VERSION_M(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case 'A':
	if (strEQ(name + 13, "AJOR")) {	/* MNG_VERSION_M removed */
#ifdef MNG_VERSION_MAJOR
	    return MNG_VERSION_MAJOR;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 13, "INOR")) {	/* MNG_VERSION_M removed */
#ifdef MNG_VERSION_MINOR
	    return MNG_VERSION_MINOR;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_VE(char *name, int len, int arg)
{
    if (6 + 6 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 6]) {
    case 'D':
	if (strEQ(name + 6, "RSION_DLL")) {	/* MNG_VE removed */
#ifdef MNG_VERSION_DLL
	    return MNG_VERSION_DLL;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 6,"RSION_", 6))
	    break;
	return constant_MNG_VERSION_M(name, len, arg);
    case 'R':
	if (strEQ(name + 6, "RSION_RELEASE")) {	/* MNG_VE removed */
#ifdef MNG_VERSION_RELEASE
	    return MNG_VERSION_RELEASE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 6, "RSION_SO")) {	/* MNG_VE removed */
#ifdef MNG_VERSION_SO
	    return MNG_VERSION_SO;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_V(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'E':
	return constant_MNG_VE(name, len, arg);
    case 'I':
	if (strEQ(name + 5, "IEWABLE")) {	/* MNG_V removed */
#ifdef MNG_VIEWABLE
	    return MNG_VIEWABLE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_FILTER_N(char *name, int len, int arg)
{
    if (12 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 1]) {
    case 'N':
	if (strEQ(name + 12, "ONE")) {	/* MNG_FILTER_N removed */
#ifdef MNG_FILTER_NONE
	    return MNG_FILTER_NONE;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 12, "O_DIFFERING")) {	/* MNG_FILTER_N removed */
#ifdef MNG_FILTER_NO_DIFFERING
	    return MNG_FILTER_NO_DIFFERING;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_FILTER_A(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case 'D':
	if (strEQ(name + 12, "DAPTIVE")) {	/* MNG_FILTER_A removed */
#ifdef MNG_FILTER_ADAPTIVE
	    return MNG_FILTER_ADAPTIVE;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 12, "VERAGE")) {	/* MNG_FILTER_A removed */
#ifdef MNG_FILTER_AVERAGE
	    return MNG_FILTER_AVERAGE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_FILT(char *name, int len, int arg)
{
    if (8 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case 'A':
	if (!strnEQ(name + 8,"ER_", 3))
	    break;
	return constant_MNG_FILTER_A(name, len, arg);
    case 'D':
	if (strEQ(name + 8, "ER_DIFFERING")) {	/* MNG_FILT removed */
#ifdef MNG_FILTER_DIFFERING
	    return MNG_FILTER_DIFFERING;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (!strnEQ(name + 8,"ER_", 3))
	    break;
	return constant_MNG_FILTER_N(name, len, arg);
    case 'P':
	if (strEQ(name + 8, "ER_PAETH")) {	/* MNG_FILT removed */
#ifdef MNG_FILTER_PAETH
	    return MNG_FILTER_PAETH;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 8, "ER_SUB")) {	/* MNG_FILT removed */
#ifdef MNG_FILTER_SUB
	    return MNG_FILTER_SUB;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 8, "ER_UP")) {	/* MNG_FILT removed */
#ifdef MNG_FILTER_UP
	    return MNG_FILTER_UP;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_FILL(char *name, int len, int arg)
{
    if (8 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 7]) {
    case 'L':
	if (strEQ(name + 8, "METHOD_LEFTBITREPLICATE")) {	/* MNG_FILL removed */
#ifdef MNG_FILLMETHOD_LEFTBITREPLICATE
	    return MNG_FILLMETHOD_LEFTBITREPLICATE;
#else
	    goto not_there;
#endif
	}
    case 'Z':
	if (strEQ(name + 8, "METHOD_ZEROFILL")) {	/* MNG_FILL removed */
#ifdef MNG_FILLMETHOD_ZEROFILL
	    return MNG_FILLMETHOD_ZEROFILL;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_FI(char *name, int len, int arg)
{
    if (6 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'L':
	if (!strnEQ(name + 6,"L", 1))
	    break;
	return constant_MNG_FILL(name, len, arg);
    case 'T':
	if (!strnEQ(name + 6,"L", 1))
	    break;
	return constant_MNG_FILT(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_FRAMI(char *name, int len, int arg)
{
    if (9 + 7 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 7]) {
    case '1':
	if (strEQ(name + 9, "NGMODE_1")) {	/* MNG_FRAMI removed */
#ifdef MNG_FRAMINGMODE_1
	    return MNG_FRAMINGMODE_1;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 9, "NGMODE_2")) {	/* MNG_FRAMI removed */
#ifdef MNG_FRAMINGMODE_2
	    return MNG_FRAMINGMODE_2;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 9, "NGMODE_3")) {	/* MNG_FRAMI removed */
#ifdef MNG_FRAMINGMODE_3
	    return MNG_FRAMINGMODE_3;
#else
	    goto not_there;
#endif
	}
    case '4':
	if (strEQ(name + 9, "NGMODE_4")) {	/* MNG_FRAMI removed */
#ifdef MNG_FRAMINGMODE_4
	    return MNG_FRAMINGMODE_4;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 9, "NGMODE_NOCHANGE")) {	/* MNG_FRAMI removed */
#ifdef MNG_FRAMINGMODE_NOCHANGE
	    return MNG_FRAMINGMODE_NOCHANGE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_FR(char *name, int len, int arg)
{
    if (6 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 2]) {
    case 'E':
	if (strEQ(name + 6, "AMENRTOOHIGH")) {	/* MNG_FR removed */
#ifdef MNG_FRAMENRTOOHIGH
	    return MNG_FRAMENRTOOHIGH;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (!strnEQ(name + 6,"AM", 2))
	    break;
	return constant_MNG_FRAMI(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_FL(char *name, int len, int arg)
{
    if (6 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case 'C':
	if (strEQ(name + 6, "AG_COMPRESSED")) {	/* MNG_FL removed */
#ifdef MNG_FLAG_COMPRESSED
	    return MNG_FLAG_COMPRESSED;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 6, "AG_UNCOMPRESSED")) {	/* MNG_FL removed */
#ifdef MNG_FLAG_UNCOMPRESSED
	    return MNG_FLAG_UNCOMPRESSED;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_FUL(char *name, int len, int arg)
{
    if (7 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 3]) {
    case 'L':
	if (strEQ(name + 7, "L_CLONE")) {	/* MNG_FUL removed */
#ifdef MNG_FULL_CLONE
	    return MNG_FULL_CLONE;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 7, "L_CMS")) {	/* MNG_FUL removed */
#ifdef MNG_FULL_CMS
	    return 1; // MNG_FULL_CMS;
#else
	    return 0; // goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_FU(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'L':
	return constant_MNG_FUL(name, len, arg);
    case 'N':
	if (strEQ(name + 6, "NCTIONINVALID")) {	/* MNG_FU removed */
#ifdef MNG_FUNCTIONINVALID
	    return MNG_FUNCTIONINVALID;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_F(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	if (strEQ(name + 5, "ALSE")) {	/* MNG_F removed */
#ifdef MNG_FALSE
	    return MNG_FALSE;
#else
	    goto not_there;
#endif
	}
    case 'I':
	return constant_MNG_FI(name, len, arg);
    case 'L':
	return constant_MNG_FL(name, len, arg);
    case 'N':
	if (strEQ(name + 5, "NNOTIMPLEMENTED")) {	/* MNG_F removed */
#ifdef MNG_FNNOTIMPLEMENTED
	    return MNG_FNNOTIMPLEMENTED;
#else
	    goto not_there;
#endif
	}
    case 'R':
	return constant_MNG_FR(name, len, arg);
    case 'U':
	return constant_MNG_FU(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_G(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	if (strEQ(name + 5, "AMMA_ONLY")) {	/* MNG_G removed */
#ifdef MNG_GAMMA_ONLY
	    return 1; // MNG_GAMMA_ONLY;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 5, "LOBALLENGTHERR")) {	/* MNG_G removed */
#ifdef MNG_GLOBALLENGTHERR
	    return MNG_GLOBALLENGTHERR;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INVALIDI(char *name, int len, int arg)
{
    if (12 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 1]) {
    case 'D':
	if (strEQ(name + 12, "NDEX")) {	/* MNG_INVALIDI removed */
#ifdef MNG_INVALIDINDEX
	    return MNG_INVALIDINDEX;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 12, "NTERLACE")) {	/* MNG_INVALIDI removed */
#ifdef MNG_INVALIDINTERLACE
	    return MNG_INVALIDINTERLACE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INVALIDCO(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case 'L':
	if (strEQ(name + 13, "LORTYPE")) {	/* MNG_INVALIDCO removed */
#ifdef MNG_INVALIDCOLORTYPE
	    return MNG_INVALIDCOLORTYPE;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 13, "MPRESS")) {	/* MNG_INVALIDCO removed */
#ifdef MNG_INVALIDCOMPRESS
	    return MNG_INVALIDCOMPRESS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INVALIDC(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case 'N':
	if (strEQ(name + 12, "NVSTYLE")) {	/* MNG_INVALIDC removed */
#ifdef MNG_INVALIDCNVSTYLE
	    return MNG_INVALIDCNVSTYLE;
#else
	    goto not_there;
#endif
	}
    case 'O':
	return constant_MNG_INVALIDCO(name, len, arg);
    case 'R':
	if (strEQ(name + 12, "RC")) {	/* MNG_INVALIDC removed */
#ifdef MNG_INVALIDCRC
	    return MNG_INVALIDCRC;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INVA(char *name, int len, int arg)
{
    if (8 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case 'B':
	if (strEQ(name + 8, "LIDBITDEPTH")) {	/* MNG_INVA removed */
#ifdef MNG_INVALIDBITDEPTH
	    return MNG_INVALIDBITDEPTH;
#else
	    goto not_there;
#endif
	}
    case 'C':
	if (!strnEQ(name + 8,"LID", 3))
	    break;
	return constant_MNG_INVALIDC(name, len, arg);
    case 'D':
	if (strEQ(name + 8, "LIDDELTA")) {	/* MNG_INVA removed */
#ifdef MNG_INVALIDDELTA
	    return MNG_INVALIDDELTA;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 8, "LIDENTRYIX")) {	/* MNG_INVA removed */
#ifdef MNG_INVALIDENTRYIX
	    return MNG_INVALIDENTRYIX;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 8, "LIDFILTER")) {	/* MNG_INVA removed */
#ifdef MNG_INVALIDFILTER
	    return MNG_INVALIDFILTER;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 8, "LIDHANDLE")) {	/* MNG_INVA removed */
#ifdef MNG_INVALIDHANDLE
	    return MNG_INVALIDHANDLE;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (!strnEQ(name + 8,"LID", 3))
	    break;
	return constant_MNG_INVALIDI(name, len, arg);
    case 'L':
	if (strEQ(name + 8, "LIDLENGTH")) {	/* MNG_INVA removed */
#ifdef MNG_INVALIDLENGTH
	    return MNG_INVALIDLENGTH;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 8, "LIDMETHOD")) {	/* MNG_INVA removed */
#ifdef MNG_INVALIDMETHOD
	    return MNG_INVALIDMETHOD;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 8, "LIDSIG")) {	/* MNG_INVA removed */
#ifdef MNG_INVALIDSIG
	    return MNG_INVALIDSIG;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INV(char *name, int len, int arg)
{
    switch (name[7 + 0]) {
    case 'A':
	return constant_MNG_INVA(name, len, arg);
    case 'D':
	if (strEQ(name + 7, "DELTATYPE")) {	/* MNG_INV removed */
#ifdef MNG_INVDELTATYPE
	    return MNG_INVDELTATYPE;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 7, "ENTRYTYPE")) {	/* MNG_INV removed */
#ifdef MNG_INVENTRYTYPE
	    return MNG_INVENTRYTYPE;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 7, "FILLMETHOD")) {	/* MNG_INV removed */
#ifdef MNG_INVFILLMETHOD
	    return MNG_INVFILLMETHOD;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 7, "IMAGETYPE")) {	/* MNG_INV removed */
#ifdef MNG_INVIMAGETYPE
	    return MNG_INVIMAGETYPE;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 7, "OFFSETSIZE")) {	/* MNG_INV removed */
#ifdef MNG_INVOFFSETSIZE
	    return MNG_INVOFFSETSIZE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 7, "SAMPLEDEPTH")) {	/* MNG_INV removed */
#ifdef MNG_INVSAMPLEDEPTH
	    return MNG_INVSAMPLEDEPTH;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INCLUDE_I(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case 'J':
	if (strEQ(name + 13, "JG6B")) {	/* MNG_INCLUDE_I removed */
#ifdef MNG_INCLUDE_IJG6B
	    return 1; // MNG_INCLUDE_IJG6B;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 13, "NTERLACE")) {	/* MNG_INCLUDE_I removed */
#ifdef MNG_INCLUDE_INTERLACE
	    return 1; // MNG_INCLUDE_INTERLACE;
#else
	    return 0; // goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INCLUDE_JNG_(char *name, int len, int arg)
{
    switch (name[16 + 0]) {
    case 'R':
	if (strEQ(name + 16, "READ")) {	/* MNG_INCLUDE_JNG_ removed */
#ifdef MNG_INCLUDE_JNG_READ
	    return 1; // MNG_INCLUDE_JNG_READ;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'W':
	if (strEQ(name + 16, "WRITE")) {	/* MNG_INCLUDE_JNG_ removed */
#ifdef MNG_INCLUDE_JNG_WRITE
	    return 1; // MNG_INCLUDE_JNG_WRITE;
#else
	    return 0; // goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INCLUDE_J(char *name, int len, int arg)
{
    if (13 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[13 + 2]) {
    case '\0':
	if (strEQ(name + 13, "NG")) {	/* MNG_INCLUDE_J removed */
#ifdef MNG_INCLUDE_JNG
	    return 1; // MNG_INCLUDE_JNG;
#else
	    return 0; // goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 13,"NG", 2))
	    break;
	return constant_MNG_INCLUDE_JNG_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INCLUDE_TR(char *name, int len, int arg)
{
    if (14 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[14 + 4]) {
    case 'P':
	if (strEQ(name + 14, "ACE_PROCS")) {	/* MNG_INCLUDE_TR removed */
#ifdef MNG_INCLUDE_TRACE_PROCS
	    return 1; // MNG_INCLUDE_TRACE_PROCS;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 14, "ACE_STRINGS")) {	/* MNG_INCLUDE_TR removed */
#ifdef MNG_INCLUDE_TRACE_STRINGS
	    return 1; // MNG_INCLUDE_TRACE_STRINGS;
#else
	    return 0; // goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INCLUDE_T(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case 'I':
	if (strEQ(name + 13, "IMING_PROCS")) {	/* MNG_INCLUDE_T removed */
#ifdef MNG_INCLUDE_TIMING_PROCS
	    return 1; // MNG_INCLUDE_TIMING_PROCS;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'R':
	return constant_MNG_INCLUDE_TR(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INCLUDE_D(char *name, int len, int arg)
{
    if (13 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[13 + 1]) {
    case 'S':
	if (strEQ(name + 13, "ISPLAY_PROCS")) {	/* MNG_INCLUDE_D removed */
#ifdef MNG_INCLUDE_DISPLAY_PROCS
	    return 1; // MNG_INCLUDE_DISPLAY_PROCS;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 13, "ITHERING")) {	/* MNG_INCLUDE_D removed */
#ifdef MNG_INCLUDE_DITHERING
	    return 1; // MNG_INCLUDE_DITHERING;
#else
	    return 0; // goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INC(char *name, int len, int arg)
{
    if (7 + 5 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 5]) {
    case 'D':
	if (!strnEQ(name + 7,"LUDE_", 5))
	    break;
	return constant_MNG_INCLUDE_D(name, len, arg);
    case 'E':
	if (strEQ(name + 7, "LUDE_ERROR_STRINGS")) {	/* MNG_INC removed */
#ifdef MNG_INCLUDE_ERROR_STRINGS
	    return 1; // MNG_INCLUDE_ERROR_STRINGS;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 7, "LUDE_FILTERS")) {	/* MNG_INC removed */
#ifdef MNG_INCLUDE_FILTERS
	    return 1; // MNG_INCLUDE_FILTERS;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'I':
	if (!strnEQ(name + 7,"LUDE_", 5))
	    break;
	return constant_MNG_INCLUDE_I(name, len, arg);
    case 'J':
	if (!strnEQ(name + 7,"LUDE_", 5))
	    break;
	return constant_MNG_INCLUDE_J(name, len, arg);
    case 'L':
	if (strEQ(name + 7, "LUDE_LCMS")) {	/* MNG_INC removed */
#ifdef MNG_INCLUDE_LCMS
	    return 1; // MNG_INCLUDE_LCMS;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 7, "LUDE_OBJECTS")) {	/* MNG_INC removed */
#ifdef MNG_INCLUDE_OBJECTS
	    return 1; // MNG_INCLUDE_OBJECTS;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 7, "LUDE_READ_PROCS")) {	/* MNG_INC removed */
#ifdef MNG_INCLUDE_READ_PROCS
	    return 1; // MNG_INCLUDE_READ_PROCS;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'T':
	if (!strnEQ(name + 7,"LUDE_", 5))
	    break;
	return constant_MNG_INCLUDE_T(name, len, arg);
    case 'W':
	if (strEQ(name + 7, "LUDE_WRITE_PROCS")) {	/* MNG_INC removed */
#ifdef MNG_INCLUDE_WRITE_PROCS
	    return 1; // MNG_INCLUDE_WRITE_PROCS;
#else
	    return 0; // goto not_there;
#endif
	}
    case 'Z':
	if (strEQ(name + 7, "LUDE_ZLIB")) {	/* MNG_INC removed */
#ifdef MNG_INCLUDE_ZLIB
	    return 1; // MNG_INCLUDE_ZLIB;
#else
	    return 0; // goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INTEN(char *name, int len, int arg)
{
    if (9 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 2]) {
    case 'A':
	if (strEQ(name + 9, "T_ABSOLUTECOLORIMETRIC")) {	/* MNG_INTEN removed */
#ifdef MNG_INTENT_ABSOLUTECOLORIMETRIC
	    return MNG_INTENT_ABSOLUTECOLORIMETRIC;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 9, "T_PERCEPTUAL")) {	/* MNG_INTEN removed */
#ifdef MNG_INTENT_PERCEPTUAL
	    return MNG_INTENT_PERCEPTUAL;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 9, "T_RELATIVECOLORIMETRIC")) {	/* MNG_INTEN removed */
#ifdef MNG_INTENT_RELATIVECOLORIMETRIC
	    return MNG_INTENT_RELATIVECOLORIMETRIC;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 9, "T_SATURATION")) {	/* MNG_INTEN removed */
#ifdef MNG_INTENT_SATURATION
	    return MNG_INTENT_SATURATION;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INTERL(char *name, int len, int arg)
{
    if (10 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 4]) {
    case 'A':
	if (strEQ(name + 10, "ACE_ADAM7")) {	/* MNG_INTERL removed */
#ifdef MNG_INTERLACE_ADAM7
	    return MNG_INTERLACE_ADAM7;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 10, "ACE_NONE")) {	/* MNG_INTERL removed */
#ifdef MNG_INTERLACE_NONE
	    return MNG_INTERLACE_NONE;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 10, "ACE_PROGRESSIVE")) {	/* MNG_INTERL removed */
#ifdef MNG_INTERLACE_PROGRESSIVE
	    return MNG_INTERLACE_PROGRESSIVE;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 10, "ACE_SEQUENTIAL")) {	/* MNG_INTERL removed */
#ifdef MNG_INTERLACE_SEQUENTIAL
	    return MNG_INTERLACE_SEQUENTIAL;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INTER(char *name, int len, int arg)
{
    switch (name[9 + 0]) {
    case 'L':
	return constant_MNG_INTERL(name, len, arg);
    case 'N':
	if (strEQ(name + 9, "NALERROR")) {	/* MNG_INTER removed */
#ifdef MNG_INTERNALERROR
	    return MNG_INTERNALERROR;
#else
	    goto not_there;
#endif
	}
	if (strEQ(name + 9, "NAL_MEMMNGMT")) {	/* MNG_INTER removed */
#ifdef MNG_INTERNAL_MEMMNGMT
	    return 1; // MNG_INTERNAL_MEMMNGMT; 
#else
	    return 0; // goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_INT(char *name, int len, int arg)
{
    if (7 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 1]) {
    case 'N':
	if (!strnEQ(name + 7,"E", 1))
	    break;
	return constant_MNG_INTEN(name, len, arg);
    case 'R':
	if (!strnEQ(name + 7,"E", 1))
	    break;
	return constant_MNG_INTER(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_IN(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'C':
	return constant_MNG_INC(name, len, arg);
    case 'T':
	return constant_MNG_INT(name, len, arg);
    case 'V':
	return constant_MNG_INV(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_IT(char *name, int len, int arg)
{
    if (6 + 9 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 9]) {
    case 'C':
	if (strEQ(name + 6, "ERACTION_CLEAR")) {	/* MNG_IT removed */
#ifdef MNG_ITERACTION_CLEAR
	    return MNG_ITERACTION_CLEAR;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 6, "ERACTION_FIRSTFRAME")) {	/* MNG_IT removed */
#ifdef MNG_ITERACTION_FIRSTFRAME
	    return MNG_ITERACTION_FIRSTFRAME;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 6, "ERACTION_LASTFRAME")) {	/* MNG_IT removed */
#ifdef MNG_ITERACTION_LASTFRAME
	    return MNG_ITERACTION_LASTFRAME;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_IMAGETY(char *name, int len, int arg)
{
    if (11 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 3]) {
    case 'J':
	if (strEQ(name + 11, "PE_JNG")) {	/* MNG_IMAGETY removed */
#ifdef MNG_IMAGETYPE_JNG
	    return MNG_IMAGETYPE_JNG;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 11, "PE_PNG")) {	/* MNG_IMAGETY removed */
#ifdef MNG_IMAGETYPE_PNG
	    return MNG_IMAGETYPE_PNG;
#else
	    goto not_there;
#endif
	}
    case 'U':
	if (strEQ(name + 11, "PE_UNKNOWN")) {	/* MNG_IMAGETY removed */
#ifdef MNG_IMAGETYPE_UNKNOWN
	    return MNG_IMAGETYPE_UNKNOWN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_IMAGET(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'O':
	if (strEQ(name + 10, "OOLARGE")) {	/* MNG_IMAGET removed */
#ifdef MNG_IMAGETOOLARGE
	    return MNG_IMAGETOOLARGE;
#else
	    goto not_there;
#endif
	}
    case 'Y':
	return constant_MNG_IMAGETY(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_IM(char *name, int len, int arg)
{
    if (6 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case 'F':
	if (strEQ(name + 6, "AGEFROZEN")) {	/* MNG_IM removed */
#ifdef MNG_IMAGEFROZEN
	    return MNG_IMAGEFROZEN;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (!strnEQ(name + 6,"AGE", 3))
	    break;
	return constant_MNG_IMAGET(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_I(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'D':
	if (strEQ(name + 5, "DATMISSING")) {	/* MNG_I removed */
#ifdef MNG_IDATMISSING
	    return MNG_IDATMISSING;
#else
	    goto not_there;
#endif
	}
    case 'M':
	return constant_MNG_IM(name, len, arg);
    case 'N':
	return constant_MNG_IN(name, len, arg);
    case 'T':
	return constant_MNG_IT(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_ZLIB_ME(char *name, int len, int arg)
{
    switch (name[11 + 0]) {
    case 'M':
	if (strEQ(name + 11, "MLEVEL")) {	/* MNG_ZLIB_ME removed */
#ifdef MNG_ZLIB_MEMLEVEL
	    return MNG_ZLIB_MEMLEVEL;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 11, "THOD")) {	/* MNG_ZLIB_ME removed */
#ifdef MNG_ZLIB_METHOD
	    return MNG_ZLIB_METHOD;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_ZLIB_M(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case 'A':
	if (strEQ(name + 10, "AXBUF")) {	/* MNG_ZLIB_M removed */
#ifdef MNG_ZLIB_MAXBUF
	    return MNG_ZLIB_MAXBUF;
#else
	    goto not_there;
#endif
	}
    case 'E':
	return constant_MNG_ZLIB_ME(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_ZLIB_(char *name, int len, int arg)
{
    switch (name[9 + 0]) {
    case 'L':
	if (strEQ(name + 9, "LEVEL")) {	/* MNG_ZLIB_ removed */
#ifdef MNG_ZLIB_LEVEL
	    return MNG_ZLIB_LEVEL;
#else
	    goto not_there;
#endif
	}
    case 'M':
	return constant_MNG_ZLIB_M(name, len, arg);
    case 'S':
	if (strEQ(name + 9, "STRATEGY")) {	/* MNG_ZLIB_ removed */
#ifdef MNG_ZLIB_STRATEGY
	    return MNG_ZLIB_STRATEGY;
#else
	    goto not_there;
#endif
	}
    case 'W':
	if (strEQ(name + 9, "WINDOWBITS")) {	/* MNG_ZLIB_ removed */
#ifdef MNG_ZLIB_WINDOWBITS
	    return MNG_ZLIB_WINDOWBITS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_Z(char *name, int len, int arg)
{
    if (5 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 3]) {
    case 'E':
	if (strEQ(name + 5, "LIBERROR")) {	/* MNG_Z removed */
#ifdef MNG_ZLIBERROR
	    return MNG_ZLIBERROR;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 5,"LIB", 3))
	    break;
	return constant_MNG_ZLIB_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_JPEG_(char *name, int len, int arg)
{
    switch (name[9 + 0]) {
    case 'D':
	if (strEQ(name + 9, "DCT")) {	/* MNG_JPEG_ removed */
#ifdef MNG_JPEG_DCT
	    return MNG_JPEG_DCT;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 9, "MAXBUF")) {	/* MNG_JPEG_ removed */
#ifdef MNG_JPEG_MAXBUF
	    return MNG_JPEG_MAXBUF;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 9, "OPTIMIZED")) {	/* MNG_JPEG_ removed */
#ifdef MNG_JPEG_OPTIMIZED
	    return MNG_JPEG_OPTIMIZED;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 9, "PROGRESSIVE")) {	/* MNG_JPEG_ removed */
#ifdef MNG_JPEG_PROGRESSIVE
	    return MNG_JPEG_PROGRESSIVE;
#else
	    goto not_there;
#endif
	}
    case 'Q':
	if (strEQ(name + 9, "QUALITY")) {	/* MNG_JPEG_ removed */
#ifdef MNG_JPEG_QUALITY
	    return MNG_JPEG_QUALITY;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 9, "SMOOTHING")) {	/* MNG_JPEG_ removed */
#ifdef MNG_JPEG_SMOOTHING
	    return MNG_JPEG_SMOOTHING;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_J(char *name, int len, int arg)
{
    if (5 + 3 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 3]) {
    case 'B':
	if (strEQ(name + 5, "PEGBUFTOOSMALL")) {	/* MNG_J removed */
#ifdef MNG_JPEGBUFTOOSMALL
	    return MNG_JPEGBUFTOOSMALL;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 5, "PEGERROR")) {	/* MNG_J removed */
#ifdef MNG_JPEGERROR
	    return MNG_JPEGERROR;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 5, "PEGPARMSERR")) {	/* MNG_J removed */
#ifdef MNG_JPEGPARMSERR
	    return MNG_JPEGPARMSERR;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 5,"PEG", 3))
	    break;
	return constant_MNG_JPEG_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_LOC(char *name, int len, int arg)
{
    if (7 + 6 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 6]) {
    case 'A':
	if (strEQ(name + 7, "ATION_ABSOLUTE")) {	/* MNG_LOC removed */
#ifdef MNG_LOCATION_ABSOLUTE
	    return MNG_LOCATION_ABSOLUTE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 7, "ATION_RELATIVE")) {	/* MNG_LOC removed */
#ifdef MNG_LOCATION_RELATIVE
	    return MNG_LOCATION_RELATIVE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_LO(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'C':
	return constant_MNG_LOC(name, len, arg);
    case 'O':
	if (strEQ(name + 6, "OPWITHCACHEOFF")) {	/* MNG_LO removed */
#ifdef MNG_LOOPWITHCACHEOFF
	    return MNG_LOOPWITHCACHEOFF;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_LCMS_(char *name, int len, int arg)
{
    if (9 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 2]) {
    case 'H':
	if (strEQ(name + 9, "NOHANDLE")) {	/* MNG_LCMS_ removed */
#ifdef MNG_LCMS_NOHANDLE
	    return MNG_LCMS_NOHANDLE;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 9, "NOMEM")) {	/* MNG_LCMS_ removed */
#ifdef MNG_LCMS_NOMEM
	    return MNG_LCMS_NOMEM;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 9, "NOTRANS")) {	/* MNG_LCMS_ removed */
#ifdef MNG_LCMS_NOTRANS
	    return MNG_LCMS_NOTRANS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_LC(char *name, int len, int arg)
{
    if (6 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 2]) {
    case 'E':
	if (strEQ(name + 6, "MSERROR")) {	/* MNG_LC removed */
#ifdef MNG_LCMSERROR
	    return MNG_LCMSERROR;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 6,"MS", 2))
	    break;
	return constant_MNG_LCMS_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_L(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	if (strEQ(name + 5, "AYERNRTOOHIGH")) {	/* MNG_L removed */
#ifdef MNG_LAYERNRTOOHIGH
	    return MNG_LAYERNRTOOHIGH;
#else
	    goto not_there;
#endif
	}
    case 'C':
	return constant_MNG_LC(name, len, arg);
    case 'O':
	return constant_MNG_LO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_MNG_V(char *name, int len, int arg)
{
    if (9 + 8 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[9 + 8]) {
    case 'A':
	if (strEQ(name + 9, "ERSION_MAJ")) {	/* MNG_MNG_V removed */
#ifdef MNG_MNG_VERSION_MAJ
	    return MNG_MNG_VERSION_MAJ;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 9, "ERSION_MIN")) {	/* MNG_MNG_V removed */
#ifdef MNG_MNG_VERSION_MIN
	    return MNG_MNG_VERSION_MIN;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_MNG_(char *name, int len, int arg)
{
    switch (name[8 + 0]) {
    case 'D':
	if (strEQ(name + 8, "DRAFT")) {	/* MNG_MNG_ removed */
#ifdef MNG_MNG_DRAFT
	    return MNG_MNG_DRAFT;
#else
	    goto not_there;
#endif
	}
    case 'V':
	return constant_MNG_MNG_V(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_MN(char *name, int len, int arg)
{
    if (6 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'T':
	if (strEQ(name + 6, "GTOOCOMPLEX")) {	/* MNG_MN removed */
#ifdef MNG_MNGTOOCOMPLEX
	    return MNG_MNGTOOCOMPLEX;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 6,"G", 1))
	    break;
	return constant_MNG_MNG_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_MA(char *name, int len, int arg)
{
    if (6 + 2 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 2]) {
    case 'I':
	if (strEQ(name + 6, "X_IDAT_SIZE")) {	/* MNG_MA removed */
#ifdef MNG_MAX_IDAT_SIZE
	    return MNG_MAX_IDAT_SIZE;
#else
	    goto not_there;
#endif
	}
    case 'J':
	if (strEQ(name + 6, "X_JDAT_SIZE")) {	/* MNG_MA removed */
#ifdef MNG_MAX_JDAT_SIZE
	    return MNG_MAX_JDAT_SIZE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MNG_M(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'A':
	return constant_MNG_MA(name, len, arg);
    case 'N':
	return constant_MNG_MN(name, len, arg);
    case 'U':
	if (strEQ(name + 5, "ULTIPLEERROR")) {	/* MNG_M removed */
#ifdef MNG_MULTIPLEERROR
	    return MNG_MULTIPLEERROR;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    if (0 + 4 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[0 + 4]) {
    case 'A':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_A(name, len, arg);
    case 'B':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_B(name, len, arg);
    case 'C':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_C(name, len, arg);
    case 'D':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_D(name, len, arg);
    case 'E':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_E(name, len, arg);
    case 'F':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_F(name, len, arg);
    case 'G':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_G(name, len, arg);
    case 'I':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_I(name, len, arg);
    case 'J':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_J(name, len, arg);
    case 'K':
	if (strEQ(name + 0, "MNG_KEYWORDNULL")) {	/*  removed */
#ifdef MNG_KEYWORDNULL
	    return MNG_KEYWORDNULL;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_L(name, len, arg);
    case 'M':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_M(name, len, arg);
    case 'N':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_N(name, len, arg);
    case 'O':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_O(name, len, arg);
    case 'P':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_P(name, len, arg);
    case 'R':
	if (strEQ(name + 0, "MNG_RENUMBER")) {	/*  removed */
#ifdef MNG_RENUMBER
	    return MNG_RENUMBER;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_S(name, len, arg);
    case 'T':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_T(name, len, arg);
    case 'U':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_U(name, len, arg);
    case 'V':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_V(name, len, arg);
    case 'W':
	if (strEQ(name + 0, "MNG_WRONGCHUNK")) {	/*  removed */
#ifdef MNG_WRONGCHUNK
	    return MNG_WRONGCHUNK;
#else
	    goto not_there;
#endif
	}
    case 'Z':
	if (!strnEQ(name + 0,"MNG_", 4))
	    break;
	return constant_MNG_Z(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


//==============================================================================
//                   CONSTANTS AND MACROS FOR INTERNAL USE
//==============================================================================

// used to interact with warnings::register
static unsigned long warn_category = 0;

// keys for private data
static char * _MNG_HANDLE      = "_my_handle";
static char * _MNG_DATA        = "_my_data";
static char * _MNG_TEMP        = "_my_scratchpad";

// keys for callback functions (text is also used in warning messages)
static char * _MNG_MEMALLOC       = "memalloc";
static char * _MNG_MEMFREE        = "memfree";
static char * _MNG_OPENSTREAM     = "openstream";
static char * _MNG_CLOSESTREAM    = "closestream";
static char * _MNG_READDATA       = "readdata";
static char * _MNG_WRITEDATA      = "writedata";
static char * _MNG_ERRORPROC      = "errorproc";
static char * _MNG_TRACEPROC      = "traceproc";
static char * _MNG_PROCESSHEADER  = "processheader";
static char * _MNG_PROCESSTEXT    = "processtext";
static char * _MNG_PROCESSSAVE    = "processsave";
static char * _MNG_PROCESSSEEK    = "processseek";
static char * _MNG_PROCESSNEED    = "processneed";
static char * _MNG_PROCESSMEND    = "processmend";
static char * _MNG_PROCESSUNKNOWN = "processunknown";
static char * _MNG_PROCESSTERM    = "processterm";
static char * _MNG_GETCANVASLINE  = "getcanvasline";
static char * _MNG_GETBKGDLINE    = "getbkgdline";
static char * _MNG_GETALPHALINE   = "getalphaline";
static char * _MNG_REFRESH        = "refresh";
static char * _MNG_GETTICKCOUNT   = "gettickcount";
static char * _MNG_SETTIMER       = "settimer";
static char * _MNG_PROCESSGAMMA   = "processgamma";
static char * _MNG_PROCESSCHROMA  = "processchroma";
static char * _MNG_PROCESSSRGB    = "processsrgb";
static char * _MNG_PROCESSICCP    = "processiccp";
static char * _MNG_PROCESSAROW    = "processarow";
static char * _MNG_ITERATECHUNK   = "iteratechunk";

// this one is special because I made it up for those functions
// that take a callback function.  I'm calling them one-shot callbacks,
// because we're really not supposed to store them anywhere.
static char * _MNG_GETCANVASLINE_ONESHOT = "getcanvasline_oneshot";

// typedef to replace mng_handle when we don't want to treat it as an object (i.e. hChunks)
typedef void * mng_chunkhandle;


//==============================================================================
//                   I/F functions that are version dependent
//==============================================================================
// new functions for v1.0.3
#if (    ((MNG_VERSION_MAJOR  > 1))                                                           \
      || ((MNG_VERSION_MAJOR == 1) && (MNG_VERSION_MINOR  > 0))                               \
      || ((MNG_VERSION_MAJOR == 1) && (MNG_VERSION_MINOR == 0) && (MNG_VERSION_RELEASE >= 3)) \
    )
#define _MNG_GET_LASTBACKCHUNK(hndl,red,green,blue,mand) (mng_get_lastbackchunk((hndl),(red),(green),(blue),(mand)))
#else
#define _MNG_GET_LASTBACKCHUNK(hndl,red,green,blue,mand) \
      (warn("mng_get_lastbackchunk() is not implemented in this version of libmng\n" \
               "Please update your version of libmng to at least 1.0.3\n"),          \
       MNG_FUNCTIONINVALID)
#endif



//==============================================================================
//                   Min / Max Macros
//==============================================================================
#ifndef min
#define min(x,y) ((x)<(y)?(x):(y))
#endif

#ifndef max
#define max(x,y) ((x)>(y)?(x):(y))
#endif


//==============================================================================
//                   Convenience Macros
//==============================================================================

// this is used in the typemap file
#define _MNG_GET_HANDLE(arg) (*(hv_fetch((HV*)SvRV((arg)), _MNG_HANDLE, strlen(_MNG_HANDLE), 0)))

// this gives us an element of the hash in the userdata from the MNG handle
// it will create the entry if it doesn't already exist
#define _MNG_GETPRIVATE(hndl,field) (*hv_fetch((HV*)mng_get_userdata(hndl), field, strlen(field), 1))

// this will get us a reference to our object, given the handle
#define _MNG_GETOBJREF(hndl) newRV_inc((SV*)mng_get_userdata(hndl))

// every place that uses this should be changed to construct a PERL array
// in memory and return that array as a reference.
#define CHAR_PTR_CAST(x) ((char*)x)


//==============================================================================
//                   Macros for writing callback functionality
//==============================================================================
static void my_warn( const char *pat, ... )
{
   // do warnings if:
   // 1.  (PL_dowarn & G_WARN_ALL_OFF) is false and 
   // 2.     (PL_dowarn & G_WARN_ALL_ON)  is true or
   // 3.     ckWARN(warn_category) is true 
// bool do_ckWarn_d = ckWARN_d(warn_category);
   bool do_ckWarn   = ckWARN(warn_category);
   bool do_warn     = !(PL_dowarn & G_WARN_ALL_OFF) && ( PL_dowarn & G_WARN_ALL_ON || do_ckWarn );

   va_list marker;
   va_start( marker, pat );
   if ( do_warn ) warn(pat, marker);
// warn("Warnings are %s (PL_dowarn=0x%x)(do_ckWarn=%d,do_ckWarn_d=%d)\n", do_warn ? "on":"off", PL_dowarn,do_ckWarn,do_ckWarn_d);
   va_end(marker);
}



//==============================================================================
//                   Macros for writing callback functionality
//==============================================================================

#define VERIFY_CBFN_OR_RETURN( hHandle, error, fnname )                       \
   SV * cbfn = _MNG_GETPRIVATE(hHandle, fnname);                              \
                                                                              \
   while ( cbfn != NULL && SvROK(cbfn) ) { cbfn=SvRV(cbfn); }                 \
                                                                              \
   /* The first case doesn't seem to work.                                    \
      The second case is an empirical hack.                                   \
      Return if they've assigned 'undef' to the callback function */          \
   if ( cbfn == &PL_sv_undef ) return error;                                  \
   if ( !SvROK(cbfn) && SvTYPE(cbfn)==SVt_RV ) return error;                  \
                                                                              \
   if ( cbfn == NULL )                                                        \
   {                                                                          \
      my_warn( "%s: callback function not registered", fnname );              \
      return error;                                                           \
   }                                                                          \
                                                                              \
   if ( SvTYPE(cbfn) != SVt_PVCV )                                            \
   {                                                                          \
      int t=SvTYPE(cbfn);                                                     \
      my_warn( "%s: wrong type registered for callback function", fnname );   \
      return error;                                                           \
   }                                                                          \
   // this space intentionally left blank


#define PREPARE_PERL_STACK()                                                  \
   /* dSP; */                                                                 \
      int count;                                                              \
      ENTER;                                                                  \
      SAVETMPS;                                                               \
      PUSHMARK(SP);                                                           \
      // this space intentionally left blank


#define CALL_CBFN_SET_RETVAL(retval,op)                                       \
      PUTBACK;                                                                \
      count = perl_call_sv( cbfn, G_SCALAR );                                 \
      SPAGAIN;                                                                \
      while (count-- > 0) retval = op;  /* eat the return stack */            \
      FREETMPS;                                                               \
      LEAVE;                                                                  \
      // this space intentionally left blank



//==============================================================================
//                   Function and Macro for writing Perl XS code
//==============================================================================

int check_cbfn( mng_handle hHandle, const char * fnname )
{
   VERIFY_CBFN_OR_RETURN( hHandle, 0, fnname );
   return 1;
}

int store_cbfn( mng_handle hHandle, const char * fnname, SV *cbfn )
{
   // store the callback as it is given to us, but put it in a temporary slot
   sv_setsv( _MNG_GETPRIVATE(hHandle, _MNG_TEMP), cbfn );

   // now verify that it's OK.  This will return 0 if something went wrong
   if ( ! check_cbfn( hHandle, _MNG_TEMP ) )
   {
      return 0;
   }

   // set the callback function in the correct place now
   sv_setsv( _MNG_GETPRIVATE(hHandle, fnname), cbfn );

   return 1;
}

// use some preprocessor string concatination to make happy magic
#define IF_STORE_THEN_SET_CBFN( hHandle, key, procname, fProc )               \
      if ( store_cbfn( hHandle, key, fProc ) )                                \
      {                                                                       \
         RETVAL=mng_setcb_##procname( hHandle, &_mng_##procname );            \
      }                                                                       \
      else                                                                    \
      {                                                                       \
         RETVAL=mng_setcb_##procname( hHandle, NULL );                        \
      }                                                                       \
      // this space intentionally left blank


//==============================================================================
//  Macro to fix NULL return pointers that will be represented as PERL strings
//==============================================================================

// We often make a PERL string by specifying the pointer and length.
// if that length is zero, PERL will go off and call strlen() on the string.
// That's bad.  Make sure that PERL gets a NUL terminated empty string in this
// case.
#define FIX_NULL_PTR(ptr,len)        \
   if ( ptr == NULL || len == 0 ) {  \
      len = 0;                       \
      ((char*)ptr) = "\0\0\0\0";     \
   }                                 \
   // this space intentionally left blank

// we always pass in a zero length for strings, so PERL can determine their
// length.  A NULL pointer is always bad in this case
#define FIX_NULL_STRING(ptr)                     \
   if ( ptr == NULL ) ((char*)ptr) = "\0\0\0\0"; \
   // this space intentionally left blank


//==============================================================================
//                   MNG HIGH-LEVEL CALLBACK FUNCTIONS (C code)
//==============================================================================

/* memory management callbacks */
static mng_ptr MNG_DECL _mng_memalloc (mng_size_t  iLen)
{
   mng_ptr rv = (mng_ptr) malloc( iLen );
// my_warn("mng_memalloc: called for %d bytes, returning 0x%p\n", iLen, rv);
   memset( rv, 0, iLen );
   return rv;
}

static void MNG_DECL _mng_memfree (mng_ptr     iPtr,
                                   mng_size_t  iLen)
{
// my_warn("mng_memfree: releasing %d bytes from 0x%p\n", iLen, iPtr);
   free( iPtr );
   return;
}


/* I/O management callbacks */
static mng_bool MNG_DECL _mng_openstream (mng_handle hHandle)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_OPENSTREAM )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_closestream (mng_handle  hHandle)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_CLOSESTREAM )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_readdata (mng_handle  hHandle,
                                        mng_ptr     pBuf,
                                        mng_uint32  iBuflen,
                                        mng_uint32p pRead)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_READDATA )
   {
      dSP;
      char *ptr;
      STRLEN len;
      SV *sv_pRead = newSViv( 0 );
      SV *sv_pBuf  = newSVpvn( "", 0 );
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newRV( sv_pBuf ) ) );
      XPUSHs( sv_2mortal( newSViv( iBuflen ) ) );
      XPUSHs( sv_2mortal( newRV( sv_pRead ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)

      // assign the return parameters
      *pRead = SvIV( sv_pRead );
      ptr = SvPV_force( sv_pBuf, len );
      memcpy( pBuf, ptr, min(iBuflen,min(len,*pRead)) ); // be safe...

      if ( len != *pRead )
         my_warn ( "%s: length of pBuf != pRead (did you forget to set pRead?)", _MNG_READDATA );
      if ( min(len,*pRead) > iBuflen )
         my_warn ( "%s: Too much data supplied, extra discarded!", _MNG_READDATA );

      // make sure that these get destroyed...
      sv_2mortal(sv_pBuf);
      sv_2mortal(sv_pRead);
   }
   return rv;
}

static mng_bool MNG_DECL _mng_writedata (mng_handle  hHandle,
                                         mng_ptr     pBuf,
                                         mng_uint32  iBuflen,
                                         mng_uint32p pWritten)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_WRITEDATA )
   {
      dSP;
      SV *sv_pWritten = newSViv( 0 );
      PREPARE_PERL_STACK()
      FIX_NULL_PTR( pBuf, iBuflen );
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSVpvn( pBuf, sizeof(char) * iBuflen ) ) );
      XPUSHs( sv_2mortal( newSViv( iBuflen ) ) );
      XPUSHs( sv_2mortal( newRV( sv_pWritten ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)

      // assign the return parameters
      *pWritten = SvIV( sv_pWritten );

      if ( *pWritten > iBuflen )
         my_warn ( "%s: Too much data written, data discarded!", _MNG_WRITEDATA );
      else if ( *pWritten < iBuflen )
         my_warn ( "%s: Too little data written!", _MNG_WRITEDATA );

      // make sure that these get destroyed...
      sv_2mortal(sv_pWritten);
   }
   return rv;
}

/* error & trace processing callbacks */
static mng_bool MNG_DECL _mng_errorproc (mng_handle  hHandle,
                                         mng_int32   iErrorcode,
                                         mng_int8    iSeverity,
                                         mng_chunkid iChunkname,
                                         mng_uint32  iChunkseq,
                                         mng_int32   iExtra1,
                                         mng_int32   iExtra2,
                                         mng_pchar   zErrortext)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_ERRORPROC )
   {
      dSP;
      PREPARE_PERL_STACK()
      FIX_NULL_STRING( zErrortext );
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle)  ) );
      XPUSHs( sv_2mortal( newSViv( iErrorcode    ) ) );
      XPUSHs( sv_2mortal( newSViv( iSeverity     ) ) );
      XPUSHs( sv_2mortal( newSViv( iChunkname    ) ) );
      XPUSHs( sv_2mortal( newSViv( iChunkseq     ) ) );
      XPUSHs( sv_2mortal( newSViv( iExtra1       ) ) );
      XPUSHs( sv_2mortal( newSViv( iExtra2       ) ) );
      XPUSHs( sv_2mortal( newSVpv( zErrortext, 0 ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_traceproc (mng_handle  hHandle,
                                         mng_int32   iFuncnr,
                                         mng_int32   iFuncseq,
                                         mng_pchar   zFuncname)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_TRACEPROC )
   {
      dSP;
      PREPARE_PERL_STACK()
      FIX_NULL_STRING( zFuncname );
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSViv( iFuncnr      ) ) );
      XPUSHs( sv_2mortal( newSViv( iFuncseq     ) ) );
      XPUSHs( sv_2mortal( newSVpv( zFuncname, 0 ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

/* read processing callbacks */
static mng_bool MNG_DECL _mng_processheader (mng_handle  hHandle,
                                             mng_uint32  iWidth,
                                             mng_uint32  iHeight)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSHEADER )
   {
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSViv( iWidth       ) ) );
      XPUSHs( sv_2mortal( newSViv( iHeight      ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_processtext (mng_handle  hHandle,
                                           mng_uint8   iType,
                                           mng_pchar   zKeyword,
                                           mng_pchar   zText,
                                           mng_pchar   zLanguage,
                                           mng_pchar   zTranslation)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSTEXT )
   {
      dSP;
      PREPARE_PERL_STACK()
      FIX_NULL_STRING( zKeyword     );
      FIX_NULL_STRING( zText        );
      FIX_NULL_STRING( zLanguage    );
      FIX_NULL_STRING( zTranslation );
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle)    ) );
      XPUSHs( sv_2mortal( newSViv( iType           ) ) );
      XPUSHs( sv_2mortal( newSVpv( zKeyword,     0 ) ) );
      XPUSHs( sv_2mortal( newSVpv( zText,        0 ) ) );
      XPUSHs( sv_2mortal( newSVpv( zLanguage,    0 ) ) );
      XPUSHs( sv_2mortal( newSVpv( zTranslation, 0 ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_processsave (mng_handle  hHandle)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSSAVE )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_processseek (mng_handle  hHandle,
                                           mng_pchar   zName)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSSEEK )
   {  
      dSP;
      PREPARE_PERL_STACK()
      FIX_NULL_STRING( zName );
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSVpv( zName,     0 ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_processneed (mng_handle  hHandle,
                                           mng_pchar   zKeyword)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSNEED )
   {  
      dSP;
      PREPARE_PERL_STACK()
      FIX_NULL_STRING( zKeyword );
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSVpv( zKeyword,  0 ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_processmend (mng_handle  hHandle,
                                           mng_uint32  iIterationsdone,
                                           mng_uint32  iIterationsleft)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSMEND )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle)    ) );
      XPUSHs( sv_2mortal( newSViv( iIterationsdone ) ) );
      XPUSHs( sv_2mortal( newSViv( iIterationsleft ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

//
// documentation does not say if pRawdata is an "in" or "out" parameter
//
static mng_bool MNG_DECL _mng_processunknown (mng_handle  hHandle,
                                              mng_chunkid iChunkid,
                                              mng_uint32  iRawlen,
                                              mng_ptr     pRawdata)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSUNKNOWN )
   {  
      dSP;
      PREPARE_PERL_STACK()
      FIX_NULL_PTR( pRawdata, iRawlen );
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle)       ) );
      XPUSHs( sv_2mortal( newSViv ( iChunkid          ) ) );
      XPUSHs( sv_2mortal( newSViv ( iRawlen           ) ) );
      XPUSHs( sv_2mortal( newSVpvn( pRawdata, sizeof(char) * iRawlen ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_processterm (mng_handle  hHandle,
                                           mng_uint8   iTermaction,
                                           mng_uint8   iIteraction,
                                           mng_uint32  iDelay,
                                           mng_uint32  iItermax)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSTERM )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSViv( iTermaction  ) ) );
      XPUSHs( sv_2mortal( newSViv( iIteraction  ) ) );
      XPUSHs( sv_2mortal( newSViv( iDelay       ) ) );
      XPUSHs( sv_2mortal( newSViv( iItermax     ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

/* display processing callbacks */
/* COMMENTARY --

   Arrrrrrrrggggggghhhhhhhh!!!
   This particular interface sucks... because the callback functions
   here expect us to return a pointer to data in C memory somewhere.

   Well... that's hard to do from PERL, where memory comes and goes
   with garbage collection.  

*/

#define CANVAS_CALLBACK_FOR_FN(x)                                             \
      mng_ptr rv = MNG_NULL;                                                  \
      SV * sv_rv;                                                             \
      STRLEN len;                                                             \
      VERIFY_CBFN_OR_RETURN( hHandle, rv, x )                                 \
      {                                                                       \
         dSP;                                                                 \
         PREPARE_PERL_STACK()                                                 \
         XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );                     \
         XPUSHs( sv_2mortal( newSViv( iLinenr      ) ) );                     \
         CALL_CBFN_SET_RETVAL(sv_rv,POPs)                                     \
      }                                                                       \
                                                                              \
      /* forces stringification, makes SvPVX ok to update             */      \
      /* (I just hope that the pointer still refers to PERL space...) */      \
      rv = SvPV_force(sv_rv, len);                                            \
      return rv;                                                              \
      // this space intentionally left blank


static mng_ptr MNG_DECL _mng_getcanvasline (mng_handle hHandle, mng_uint32 iLinenr)
{
   CANVAS_CALLBACK_FOR_FN(_MNG_GETCANVASLINE);
}


static mng_ptr MNG_DECL _mng_getcanvasline_oneshot (mng_handle hHandle, mng_uint32 iLinenr)
{
   // this one is for all of those canvas processing functions that
   // take a callback function as the last parameter.
   CANVAS_CALLBACK_FOR_FN(_MNG_GETCANVASLINE_ONESHOT);
}


static mng_ptr MNG_DECL _mng_getbkgdline (mng_handle hHandle, mng_uint32 iLinenr)
{
   CANVAS_CALLBACK_FOR_FN(_MNG_GETBKGDLINE);
}


static mng_ptr MNG_DECL _mng_getalphaline (mng_handle hHandle, mng_uint32 iLinenr)
{
   CANVAS_CALLBACK_FOR_FN(_MNG_GETALPHALINE);
}


static mng_bool MNG_DECL _mng_refresh (mng_handle  hHandle,
                                       mng_uint32  iX,
                                       mng_uint32  iY,
                                       mng_uint32  iWidth,
                                       mng_uint32  iHeight)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_REFRESH )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSViv( iX           ) ) );
      XPUSHs( sv_2mortal( newSViv( iY           ) ) );
      XPUSHs( sv_2mortal( newSViv( iWidth       ) ) );
      XPUSHs( sv_2mortal( newSViv( iHeight      ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

/* timer management callbacks */
static mng_uint32 MNG_DECL _mng_gettickcount (mng_handle  hHandle)
{
   mng_uint32 rv = 0;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_GETTICKCOUNT )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_settimer (mng_handle  hHandle,
                                        mng_uint32  iMsecs)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_SETTIMER )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSViv( iMsecs       ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}


/* color management callbacks */
static mng_bool MNG_DECL _mng_processgamma (mng_handle  hHandle,
                                            mng_uint32  iGamma)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSGAMMA )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSViv( iGamma       ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_processchroma (mng_handle  hHandle,
                                             mng_uint32  iWhitepointx,
                                             mng_uint32  iWhitepointy,
                                             mng_uint32  iRedx,
                                             mng_uint32  iRedy,
                                             mng_uint32  iGreenx,
                                             mng_uint32  iGreeny,
                                             mng_uint32  iBluex,
                                             mng_uint32  iBluey)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSCHROMA )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSViv( iWhitepointx ) ) );
      XPUSHs( sv_2mortal( newSViv( iWhitepointy ) ) );
      XPUSHs( sv_2mortal( newSViv( iRedx        ) ) );
      XPUSHs( sv_2mortal( newSViv( iRedy        ) ) );
      XPUSHs( sv_2mortal( newSViv( iGreenx      ) ) );
      XPUSHs( sv_2mortal( newSViv( iGreeny      ) ) );
      XPUSHs( sv_2mortal( newSViv( iBluex       ) ) );
      XPUSHs( sv_2mortal( newSViv( iBluey       ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

static mng_bool MNG_DECL _mng_processsrgb (mng_handle  hHandle,
                                           mng_uint8   iRenderingintent)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSSRGB )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle)     ) );
      XPUSHs( sv_2mortal( newSViv( iRenderingintent ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}

//
// documentation does not say if pProfile is an "in" or "out" parameter
//
static mng_bool MNG_DECL _mng_processiccp (mng_handle  hHandle,
                                           mng_uint32  iProfilesize,
                                           mng_ptr     pProfile)
{
   mng_bool rv = MNG_FALSE;
   STRLEN len;
   char *ptr;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSICCP )
   {  
      dSP;
      SV *sv_pProfile;
      PREPARE_PERL_STACK()

      FIX_NULL_PTR( pProfile, iProfilesize );
      sv_pProfile = sv_2mortal( newSVpvn( pProfile, sizeof(char) * iProfilesize ) );
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSViv( iProfilesize ) ) );
      XPUSHs( sv_pProfile );
      CALL_CBFN_SET_RETVAL(rv,POPi)

      // now update their data
      ptr = SvPV_force( sv_pProfile, len );
      memcpy( pProfile, ptr, iProfilesize ); 
   }

   return rv;
}

//
// I don't know what the format of the data at pRow is, or
// how big it is.  The documentation doesn't say, and the
// code is not clear.
//
static mng_bool MNG_DECL _mng_processarow (mng_handle  hHandle,
                                           mng_uint32  iRowsamples,
                                           mng_bool    bIsRGBA16,
                                           mng_ptr     pRow)
{
   mng_bool rv = MNG_FALSE;
   STRLEN len;
   char *ptr;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_PROCESSAROW )
   {  
      dSP;
      SV *sv_pRow;
      PREPARE_PERL_STACK()

      FIX_NULL_PTR( pRow, iRowsamples );
      sv_pRow = sv_2mortal( newSVpvn( pRow, sizeof(char) * iRowsamples ) ); // sizeof(mng_uint32) * iRowsamples
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
      XPUSHs( sv_2mortal( newSViv( iRowsamples  ) ) );
      XPUSHs( sv_2mortal( newSViv( bIsRGBA16    ) ) );
      XPUSHs( sv_pRow );
      CALL_CBFN_SET_RETVAL(rv,POPi)

      // now update their pointer
      ptr = SvPV_force( sv_pRow, len );
      memcpy( pRow, ptr, iRowsamples ); 
   }

   return rv;
}

/* chunk access callback(s) */
static mng_bool MNG_DECL _mng_iteratechunk (mng_handle  hHandle,
                                            mng_handle  hChunk,
                                            mng_chunkid iChunkid,
                                            mng_uint32  iChunkseq)
{
   mng_bool rv = MNG_FALSE;
   VERIFY_CBFN_OR_RETURN( hHandle, rv, _MNG_ITERATECHUNK )
   {  
      dSP;
      PREPARE_PERL_STACK()
      XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle)   ) );
      XPUSHs( sv_2mortal( newSViv( (long)hChunk   ) ) );  // it's just a ptr
      XPUSHs( sv_2mortal( newSViv( iChunkid       ) ) );
      XPUSHs( sv_2mortal( newSViv( iChunkseq      ) ) );
      CALL_CBFN_SET_RETVAL(rv,POPi)
   }
   return rv;
}



//===============================================================================
//                    TEST FUNCTIONS
//===============================================================================




//==============================================================================
//                   PERL XS MODULE CODE STARTS HERE
//==============================================================================
MODULE = Graphics::MNG		PACKAGE = Graphics::MNG		PREFIX = mng_


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL




#===============================================================================
#                    TEST FUNCTIONS
#===============================================================================



   

#===============================================================================
#= proof-of-concept -- code to call the user back synchronously
#===============================================================================
void
mng_test_callback_fn(hHandle,cbfn)
   mng_handle hHandle
   SV *cbfn
   PROTOTYPE: $$
   PREINIT:
      int c_rv = 0;
      int count;
   PPCODE:
      if ( SvROK(cbfn) ) cbfn=SvRV(cbfn);    // allow one level of deref
      if ( SvTYPE(cbfn) != SVt_PVCV )
      {
         my_warn( "test_callback_fn: wrong type for callback function" );
         XSRETURN_UNDEF;
      }

      // in production code, this would be a good place to STORE the callback fn


      // -----------------------------------------------------------------------

      // in production code, here's how you'd CALL the callback fn
      {
         PREPARE_PERL_STACK()
         XPUSHs( sv_2mortal( _MNG_GETOBJREF(hHandle) ) );
         CALL_CBFN_SET_RETVAL(c_rv,POPi)
      }
      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );






#===============================================================================
#= This function is called by the MNG.pm module upon initialization to
#= record what category offset the warnings::register module placed us at.
#===============================================================================

void
mng_set_warn_category(offset)
   unsigned long offset
   PROTOTYPE: $
   PPCODE:
      warn_category = offset/2;  // need to half the value for use in PERL guts



#===============================================================================
#                    MNG CONSTANTS RETURNING NON-INTEGER DATA
#
# These are more verbose than normal because I'm assigning a #define constant
# instead of calling a function
#===============================================================================



#
#mng_pchar
#_MNG_DATA()
#   PROTOTYPE: 
#   CODE:
#      RETVAL = _MNG_DATA;
#   OUTPUT:
#      RETVAL
#
#mng_pchar
#_MNG_HANDLE()
#   PROTOTYPE: 
#   CODE:
#      RETVAL = _MNG_HANDLE;
#   OUTPUT:
#      RETVAL


mng_pchar
MNG_TEXT_TITLE()
   PROTOTYPE: 
   CODE:
      RETVAL = MNG_TEXT_TITLE;
   OUTPUT:
      RETVAL

mng_pchar
MNG_TEXT_AUTHOR()
   CODE:
      RETVAL = MNG_TEXT_AUTHOR;
   OUTPUT:
      RETVAL

mng_pchar
MNG_TEXT_DESCRIPTION()
   PROTOTYPE: 
   CODE:
      RETVAL = MNG_TEXT_DESCRIPTION;
   OUTPUT:
      RETVAL

mng_pchar
MNG_TEXT_COPYRIGHT()
   PROTOTYPE: 
   CODE:
      RETVAL = MNG_TEXT_COPYRIGHT;
   OUTPUT:
      RETVAL

mng_pchar
MNG_TEXT_CREATIONTIME()
   PROTOTYPE: 
   CODE:
      RETVAL = MNG_TEXT_CREATIONTIME;
   OUTPUT:
      RETVAL

mng_pchar
MNG_TEXT_SOFTWARE()
   PROTOTYPE: 
   CODE:
      RETVAL = MNG_TEXT_SOFTWARE;
   OUTPUT:
      RETVAL

mng_pchar
MNG_TEXT_DISCLAIMER()
   PROTOTYPE: 
   CODE:
      RETVAL = MNG_TEXT_DISCLAIMER;
   OUTPUT:
      RETVAL

mng_pchar
MNG_TEXT_WARNING()
   PROTOTYPE: 
   CODE:
      RETVAL = MNG_TEXT_WARNING;
   OUTPUT:
      RETVAL

mng_pchar
MNG_TEXT_SOURCE()
   PROTOTYPE: 
   CODE:
      RETVAL = MNG_TEXT_SOURCE;
   OUTPUT:
      RETVAL

mng_pchar
MNG_TEXT_COMMENT()
   PROTOTYPE: 
   CODE:
      RETVAL = MNG_TEXT_COMMENT;
   OUTPUT:
      RETVAL




#===============================================================================
#                    MNG VERSION FUNCTIONS
#
# These would normally be one-liners, but I'm making these functions
# compatible with the OO interface
#===============================================================================

mng_pchar 
mng_version_text(hHandle=NO_INIT)
   PROTOTYPE: ;$
   CODE:
      RETVAL=mng_version_text();
   OUTPUT:
      RETVAL

mng_uint8 
mng_version_so(hHandle=NO_INIT)
   PROTOTYPE: ;$
   CODE:
      RETVAL=mng_version_so();
   OUTPUT:
      RETVAL

mng_uint8 
mng_version_dll(hHandle=NO_INIT)
   PROTOTYPE: ;$
   CODE:
      RETVAL=mng_version_dll();
   OUTPUT:
      RETVAL

mng_uint8 
mng_version_major(hHandle=NO_INIT)
   PROTOTYPE: ;$
   CODE:
      RETVAL=mng_version_major();
   OUTPUT:
      RETVAL

mng_uint8 
mng_version_minor(hHandle=NO_INIT)
   PROTOTYPE: ;$
   CODE:
      RETVAL=mng_version_minor();
   OUTPUT:
      RETVAL

mng_uint8 
mng_version_release(hHandle=NO_INIT)
   PROTOTYPE: ;$
   CODE:
      RETVAL=mng_version_release();
   OUTPUT:
      RETVAL



#===============================================================================
#                    MNG HIGH-LEVEL INTERFACE FUNCTIONS
#===============================================================================

SV*
mng_initialize(userdata=&PL_sv_undef)
   SV * userdata
   PROTOTYPE: ;$
   PREINIT:
      mng_handle c_hHandle;
      HV* hash = newHV();
   CODE:
      // we're assuming that we're building with internal memory management 
      // I'm not supplying the hook for tracing right now... maybe later
      // I'll tie the output to an output file or something, or even give
      // the user a PERL callback for it (oh, but the performance woes)
      c_hHandle = mng_initialize( (mng_ptr)hash, &_mng_memalloc, &_mng_memfree, MNG_NULL );

      if ( c_hHandle == 0 )
      {
         my_warn("mng_initialize: returned NULL handle");
         XSRETURN_UNDEF;
      }

      // now add a reference to our newly created hash and store the user data
      sv_setiv(_MNG_GETPRIVATE( c_hHandle, _MNG_HANDLE ), (long)c_hHandle );
      sv_setsv(_MNG_GETPRIVATE( c_hHandle, _MNG_DATA ),   userdata        );

      // set the return value
      RETVAL = newRV_inc( (SV*)hash );

   OUTPUT:
      RETVAL


mng_retcode 
mng_reset(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_retcode 
mng_cleanup(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   PREINIT:
      void * userdata;
   CODE:
      userdata = mng_get_userdata( hHandle );

      if ( userdata != NULL )
      {
         // clean up our data
      }

      RETVAL = mng_cleanup( &hHandle );

   OUTPUT:
      RETVAL
      hHandle sv_setiv(ST(0), 0);


void
mng_getlasterror(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   PREINIT:
      // declare some local variables
      mng_int8      c_iSeverity  = 0;
      mng_chunkid   c_iChunkname = 0;
      mng_uint32    c_iChunkseq  = 0;
      mng_int32     c_iExtra1    = 0;
      mng_int32     c_iExtra2    = 0;
      mng_pchar     c_zErrortext = NULL;
      mng_retcode   c_rv;
      SV*           errortext = &PL_sv_undef;
   PPCODE:
      c_rv = mng_getlasterror ( hHandle,                    
                                &c_iSeverity,
                                &c_iChunkname,
                                &c_iChunkseq,
                                &c_iExtra1,
                                &c_iExtra2,
                                &c_zErrortext );


      // always return the mng_retcode
      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );

      // only include the extras if we DID have an error...
      if ( c_rv != MNG_NOERROR )  
      {
         FIX_NULL_STRING( c_zErrortext );
         XPUSHs( sv_2mortal( newSViv( c_iSeverity     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iChunkname    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iChunkseq     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iExtra1       ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iExtra2       ) ) );
         XPUSHs( sv_2mortal( newSVpv( c_zErrortext, 0 ) ) );
      }

# ------------------------------------------------------------
# ----------------- AUTOGENERATED CODE HERE ------------------
# ------------------------------------------------------------

mng_retcode
mng_read(hHandle)
   mng_handle hHandle
   PROTOTYPE: $

mng_retcode
mng_read_resume(hHandle)
   mng_handle hHandle
   PROTOTYPE: $

mng_retcode
mng_write(hHandle)
   mng_handle hHandle
   PROTOTYPE: $

mng_retcode
mng_create(hHandle)
   mng_handle hHandle
   PROTOTYPE: $

mng_retcode
mng_readdisplay(hHandle)
   mng_handle hHandle
   PROTOTYPE: $

mng_retcode
mng_display(hHandle)
   mng_handle hHandle
   PROTOTYPE: $

mng_retcode
mng_display_resume(hHandle)
   mng_handle hHandle
   PROTOTYPE: $

mng_retcode
mng_display_freeze(hHandle)
   mng_handle hHandle
   PROTOTYPE: $

mng_retcode
mng_display_reset(hHandle)
   mng_handle hHandle
   PROTOTYPE: $

mng_retcode
mng_display_goframe (hHandle, iFramenr)
   mng_handle hHandle
   mng_uint32 iFramenr
   PROTOTYPE: $$

mng_retcode
mng_display_golayer (hHandle, iLayernr)
   mng_handle hHandle
   mng_uint32 iLayernr
   PROTOTYPE: $$

mng_retcode
mng_display_gotime  (hHandle, iPlaytime)
   mng_handle hHandle
   mng_uint32 iPlaytime
   PROTOTYPE: $$



# ------------------------------------------------------------
# - Callback functions -- SET
# ------------------------------------------------------------

mng_retcode
mng_setcb_memalloc(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifndef MNG_INTERNAL_MEMMNGMT
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_MEMALLOC, memalloc, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_memfree(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifndef MNG_INTERNAL_MEMMNGMT
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_MEMFREE, memfree, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_openstream(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#if defined(MNG_SUPPORT_READ) || defined(MNG_SUPPORT_WRITE)
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_OPENSTREAM, openstream, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_closestream(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#if defined(MNG_SUPPORT_READ) || defined(MNG_SUPPORT_WRITE)
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_CLOSESTREAM, closestream, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_readdata(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_READ
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_READDATA, readdata, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_writedata(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_WRITE
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_WRITEDATA, writedata, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_errorproc(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#if 1
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_ERRORPROC, errorproc, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_traceproc(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_TRACE
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_TRACEPROC, traceproc, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processheader(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_READ
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSHEADER, processheader, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processtext(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_READ
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSTEXT, processtext, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processsave(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_READ
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSSAVE, processsave, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processseek(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_READ
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSSEEK, processseek, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processneed(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_READ
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSNEED, processneed, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processmend(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_READ
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSMEND, processmend, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processunknown(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_READ
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSUNKNOWN, processunknown, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processterm(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_READ
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSTERM, processterm, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_getcanvasline(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_DISPLAY
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_GETCANVASLINE, getcanvasline, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_getbkgdline(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_DISPLAY
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_GETBKGDLINE, getbkgdline, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_getalphaline(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_DISPLAY
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_GETALPHALINE, getalphaline, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_refresh(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_SUPPORT_DISPLAY
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_REFRESH, refresh, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_gettickcount(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#if 1
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_GETTICKCOUNT, gettickcount, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_settimer(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#if 1
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_SETTIMER, settimer, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processgamma(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_APP_CMS
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSGAMMA, processgamma, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processchroma(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_APP_CMS
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSCHROMA, processchroma, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processsrgb(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_APP_CMS
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSSRGB, processsrgb, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processiccp(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_APP_CMS
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSICCP, processiccp, fProc )
#endif
   OUTPUT:
      RETVAL


mng_retcode
mng_setcb_processarow(hHandle,fProc)
   mng_handle hHandle
   SV * fProc
   PROTOTYPE: $$
   CODE:
      RETVAL = MNG_NOCALLBACK;
#ifdef MNG_APP_CMS
      IF_STORE_THEN_SET_CBFN( hHandle, _MNG_PROCESSAROW, processarow, fProc )
#endif
   OUTPUT:
      RETVAL


# ------------------------------------------------------------
# - Callback functions -- GET
# ------------------------------------------------------------


SV *
mng_getcb_memalloc(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_MEMALLOC);
   OUTPUT:
      RETVAL


SV *
mng_getcb_memfree(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_MEMFREE);
   OUTPUT:
      RETVAL


SV *
mng_getcb_openstream(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_OPENSTREAM);
   OUTPUT:
      RETVAL


SV *
mng_getcb_closestream(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_CLOSESTREAM);
   OUTPUT:
      RETVAL


SV *
mng_getcb_readdata(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_READDATA);
   OUTPUT:
      RETVAL


SV *
mng_getcb_writedata(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_WRITEDATA);
   OUTPUT:
      RETVAL


SV *
mng_getcb_errorproc(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_ERRORPROC);
   OUTPUT:
      RETVAL


SV *
mng_getcb_traceproc(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_TRACEPROC);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processheader(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSHEADER);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processtext(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSTEXT);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processsave(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSSAVE);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processseek(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSSEEK);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processneed(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSNEED);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processmend(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSMEND);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processunknown(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSUNKNOWN);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processterm(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSTERM);
   OUTPUT:
      RETVAL


SV *
mng_getcb_getcanvasline(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_GETCANVASLINE);
   OUTPUT:
      RETVAL


SV *
mng_getcb_getbkgdline(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_GETBKGDLINE);
   OUTPUT:
      RETVAL


SV *
mng_getcb_getalphaline(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_GETALPHALINE);
   OUTPUT:
      RETVAL


SV *
mng_getcb_refresh(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_REFRESH);
   OUTPUT:
      RETVAL


SV *
mng_getcb_gettickcount(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_GETTICKCOUNT);
   OUTPUT:
      RETVAL


SV *
mng_getcb_settimer(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_SETTIMER);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processgamma(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSGAMMA);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processchroma(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSCHROMA);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processsrgb(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSSRGB);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processiccp(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSICCP);
   OUTPUT:
      RETVAL


SV *
mng_getcb_processarow(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL=_MNG_GETPRIVATE(hHandle,_MNG_PROCESSAROW);
   OUTPUT:
      RETVAL




# ------------------------------------------------------------
# - Accessors -- SET
# ------------------------------------------------------------



mng_retcode
mng_set_userdata(hHandle,pUserdata)
   mng_handle hHandle
   SV * pUserdata
   PROTOTYPE: $$
   CODE:
      sv_setsv(_MNG_GETPRIVATE( hHandle, _MNG_DATA ), pUserdata );
      RETVAL = MNG_NOERROR;
   OUTPUT:
      RETVAL


mng_retcode
mng_set_canvasstyle(hHandle,iStyle)
   mng_handle hHandle
   mng_uint32 iStyle
   PROTOTYPE: $$


mng_retcode
mng_set_bkgdstyle(hHandle,iStyle)
   mng_handle hHandle
   mng_uint32 iStyle
   PROTOTYPE: $$


mng_retcode
mng_set_bgcolor(hHandle,iRed,iGreen,iBlue)
   mng_handle hHandle
   mng_uint16 iRed
   mng_uint16 iGreen
   mng_uint16 iBlue
   PROTOTYPE: $$$$


mng_retcode
mng_set_usebkgd(hHandle,bUseBKGD)
   mng_handle hHandle
   mng_bool bUseBKGD
   PROTOTYPE: $$


mng_retcode
mng_set_storechunks(hHandle,bStorechunks)
   mng_handle hHandle
   mng_bool bStorechunks
   PROTOTYPE: $$


mng_retcode
mng_set_sectionbreaks(hHandle,bSectionbreaks)
   mng_handle hHandle
   mng_bool bSectionbreaks
   PROTOTYPE: $$


mng_retcode
mng_set_cacheplayback(hHandle,bCacheplayback)
   mng_handle hHandle
   mng_bool bCacheplayback
   PROTOTYPE: $$


mng_retcode
mng_set_doprogressive(hHandle,bDoProgressive)
   mng_handle hHandle
   mng_bool bDoProgressive
   PROTOTYPE: $$


mng_retcode
mng_set_srgb(hHandle,bIssRGB)
   mng_handle hHandle
   mng_bool bIssRGB
   PROTOTYPE: $$


mng_retcode
mng_set_outputprofile(hHandle,zFilename)
   mng_handle hHandle
   mng_pchar zFilename
   PROTOTYPE: $$


mng_retcode
mng_set_outputprofile2(hHandle,iProfilesize,pProfile)
   mng_handle hHandle
   mng_uint32 iProfilesize
   mng_ptr pProfile
   PROTOTYPE: $$$


mng_retcode
mng_set_outputsrgb(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_retcode
mng_set_srgbprofile(hHandle,zFilename)
   mng_handle hHandle
   mng_pchar zFilename
   PROTOTYPE: $$


mng_retcode
mng_set_srgbprofile2(hHandle,iProfilesize,pProfile)
   mng_handle hHandle
   mng_uint32 iProfilesize
   mng_ptr pProfile
   PROTOTYPE: $$$


mng_retcode
mng_set_srgbimplicit(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_retcode
mng_set_viewgamma(hHandle,dGamma)
   mng_handle hHandle
   mng_float dGamma
   PROTOTYPE: $$


mng_retcode
mng_set_displaygamma(hHandle,dGamma)
   mng_handle hHandle
   mng_float dGamma
   PROTOTYPE: $$


mng_retcode
mng_set_dfltimggamma(hHandle,dGamma)
   mng_handle hHandle
   mng_float dGamma
   PROTOTYPE: $$


mng_retcode
mng_set_viewgammaint(hHandle,iGamma)
   mng_handle hHandle
   mng_uint32 iGamma
   PROTOTYPE: $$


mng_retcode
mng_set_displaygammaint(hHandle,iGamma)
   mng_handle hHandle
   mng_uint32 iGamma
   PROTOTYPE: $$


mng_retcode
mng_set_dfltimggammaint(hHandle,iGamma)
   mng_handle hHandle
   mng_uint32 iGamma
   PROTOTYPE: $$


mng_retcode
mng_set_maxcanvaswidth(hHandle,iMaxwidth)
   mng_handle hHandle
   mng_uint32 iMaxwidth
   PROTOTYPE: $$


mng_retcode
mng_set_maxcanvasheight(hHandle,iMaxheight)
   mng_handle hHandle
   mng_uint32 iMaxheight
   PROTOTYPE: $$


mng_retcode
mng_set_maxcanvassize(hHandle,iMaxwidth,iMaxheight)
   mng_handle hHandle
   mng_uint32 iMaxwidth
   mng_uint32 iMaxheight
   PROTOTYPE: $$$


mng_retcode
mng_set_zlib_level(hHandle,iZlevel)
   mng_handle hHandle
   mng_int32 iZlevel
   PROTOTYPE: $$


mng_retcode
mng_set_zlib_method(hHandle,iZmethod)
   mng_handle hHandle
   mng_int32 iZmethod
   PROTOTYPE: $$


mng_retcode
mng_set_zlib_windowbits(hHandle,iZwindowbits)
   mng_handle hHandle
   mng_int32 iZwindowbits
   PROTOTYPE: $$


mng_retcode
mng_set_zlib_memlevel(hHandle,iZmemlevel)
   mng_handle hHandle
   mng_int32 iZmemlevel
   PROTOTYPE: $$


mng_retcode
mng_set_zlib_strategy(hHandle,iZstrategy)
   mng_handle hHandle
   mng_int32 iZstrategy
   PROTOTYPE: $$


mng_retcode
mng_set_zlib_maxidat(hHandle,iMaxIDAT)
   mng_handle hHandle
   mng_uint32 iMaxIDAT
   PROTOTYPE: $$


mng_retcode
mng_set_jpeg_dctmethod(hHandle,eJPEGdctmethod)
   mng_handle hHandle
   mngjpeg_dctmethod eJPEGdctmethod
   PROTOTYPE: $$


mng_retcode
mng_set_jpeg_quality(hHandle,iJPEGquality)
   mng_handle hHandle
   mng_int32 iJPEGquality
   PROTOTYPE: $$


mng_retcode
mng_set_jpeg_smoothing(hHandle,iJPEGsmoothing)
   mng_handle hHandle
   mng_int32 iJPEGsmoothing
   PROTOTYPE: $$


mng_retcode
mng_set_jpeg_progressive(hHandle,bJPEGprogressive)
   mng_handle hHandle
   mng_bool bJPEGprogressive
   PROTOTYPE: $$


mng_retcode
mng_set_jpeg_optimized(hHandle,bJPEGoptimized)
   mng_handle hHandle
   mng_bool bJPEGoptimized
   PROTOTYPE: $$


mng_retcode
mng_set_jpeg_maxjdat(hHandle,iMaxJDAT)
   mng_handle hHandle
   mng_uint32 iMaxJDAT
   PROTOTYPE: $$


mng_retcode
mng_set_suspensionmode(hHandle,bSuspensionmode)
   mng_handle hHandle
   mng_bool bSuspensionmode
   PROTOTYPE: $$


mng_retcode
mng_set_speed(hHandle,iSpeed)
   mng_handle hHandle
   mng_speedtype iSpeed
   PROTOTYPE: $$


# ------------------------------------------------------------
# - Accessors -- GET
# ------------------------------------------------------------

SV *     
mng_get_userdata(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   CODE:
      RETVAL = newSVsv(_MNG_GETPRIVATE( hHandle, _MNG_DATA ));
   OUTPUT:
      RETVAL


mng_imgtype
mng_get_sigtype(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_imgtype
mng_get_imagetype(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_imagewidth(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_imageheight(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_ticks(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_framecount(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_layercount(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_playtime(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_simplicity(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_bitdepth(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_colortype(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_compression(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_filter(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_interlace(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_alphabitdepth(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_alphacompression(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_alphafilter(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_alphainterlace(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_alphadepth(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint8
mng_get_refreshpass(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_canvasstyle(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_bkgdstyle(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


void
mng_get_bgcolor(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   PREINIT:
      mng_retcode      c_rv;
      mng_uint16       c_iRed;
      mng_uint16       c_iGreen;
      mng_uint16       c_iBlue;
   PPCODE:
      c_rv = mng_get_bgcolor(hHandle,&c_iRed,&c_iGreen,&c_iBlue);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iRed    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iGreen  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBlue   ) ) );
      }


mng_bool
mng_get_usebkgd(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_get_storechunks(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_get_sectionbreaks(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_get_cacheplayback(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_get_doprogressive(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_get_srgb(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_float
mng_get_viewgamma(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_float
mng_get_displaygamma(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_float
mng_get_dfltimggamma(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_viewgammaint(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_displaygammaint(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_dfltimggammaint(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_maxcanvaswidth(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_maxcanvasheight(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_int32
mng_get_zlib_level(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_int32
mng_get_zlib_method(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_int32
mng_get_zlib_windowbits(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_int32
mng_get_zlib_memlevel(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_int32
mng_get_zlib_strategy(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_zlib_maxidat(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mngjpeg_dctmethod
mng_get_jpeg_dctmethod(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_int32
mng_get_jpeg_quality(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_int32
mng_get_jpeg_smoothing(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_get_jpeg_progressive(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_get_jpeg_optimized(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_jpeg_maxjdat(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_get_suspensionmode(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_speedtype
mng_get_speed(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_imagelevel(hHandle)
   mng_handle hHandle
   PROTOTYPE: $

mng_retcode
mng_get_lastbackchunk(hHandle)
   mng_handle hHandle
   PROTOTYPE: $
   PREINIT:
      mng_retcode  c_rv;
      mng_uint16   c_iRed       = 0;
      mng_uint16   c_iGreen     = 0;
      mng_uint16   c_iBlue      = 0;
      mng_uint8    c_iMandatory = 0;

   PPCODE:
      // this function was introduced in v1.0.3
      c_rv = _MNG_GET_LASTBACKCHUNK(hHandle,&c_iRed,&c_iGreen,&c_iBlue,&c_iMandatory);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iRed          ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iGreen        ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBlue         ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMandatory    ) ) );
      }


mng_uint32
mng_get_starttime(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_runtime(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_currentframe(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_currentlayer(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_uint32
mng_get_currentplaytime(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_status_error(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_status_reading(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_status_suspendbreak(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_status_creating(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_status_writing(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_status_displaying(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_status_running(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


mng_bool
mng_status_timerbreak(hHandle)
   mng_handle hHandle
   PROTOTYPE: $


# ------------------------------------------------------------
# ---------- END OF AUTOGENERATED CODE -----------------------
# ------------------------------------------------------------


mng_retcode
mng_iterate_chunks(hHandle,iChunkseq,fProc)
   mng_handle       hHandle
   mng_uint32       iChunkseq
   SV *             fProc
   PROTOTYPE: $$$
   PREINIT:
      mng_iteratechunk c_fProc;
   CODE:
#ifdef MNG_ACCESS_CHUNKS
      if ( store_cbfn( hHandle, _MNG_ITERATECHUNK, fProc ) )
      {
         RETVAL = mng_iterate_chunks(hHandle,iChunkseq,&_mng_iteratechunk);
      }
      else
#endif
      {
         RETVAL = MNG_NOCALLBACK;
      }

   OUTPUT:
      RETVAL



# ------------------------------------------------------------
# ---------- mng_getchunk_* functions
# ------------------------------------------------------------


void
mng_getchunk_ihdr(hHandle, hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk       = (mng_handle) hChunk;
      mng_uint32       c_iWidth       = 0;
      mng_uint32       c_iHeight      = 0;
      mng_uint8        c_iBitdepth    = 0;
      mng_uint8        c_iColortype   = 0;
      mng_uint8        c_iCompression = 0;
      mng_uint8        c_iFilter      = 0;
      mng_uint8        c_iInterlace   = 0;
   PPCODE:
      c_rv = mng_getchunk_ihdr(hHandle,c_hChunk,&c_iWidth,&c_iHeight,&c_iBitdepth,&c_iColortype,&c_iCompression,&c_iFilter,&c_iInterlace);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iWidth        ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iHeight       ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBitdepth     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iColortype    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iCompression  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iFilter       ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iInterlace    ) ) );
      }


void
mng_getchunk_plte(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk   = (mng_handle) hChunk;
      mng_uint32       c_iCount   = 0;
      mng_palette8     c_aPalette;
   PPCODE:
      c_rv = mng_getchunk_plte(hHandle,c_hChunk,&c_iCount,&c_aPalette);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iCount    ) ) );
         XPUSHs( sv_2mortal( newSVpvn( CHAR_PTR_CAST(c_aPalette), sizeof(c_aPalette) ) ) );
      }



void
mng_getchunk_idat(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk   = (mng_handle) hChunk;
      mng_uint32       c_iRawlen  = 0;
      mng_ptr          c_pRawdata = NULL;

   PPCODE:
      c_rv = mng_getchunk_idat(hHandle,c_hChunk,&c_iRawlen,&c_pRawdata);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_pRawdata, c_iRawlen );
         XPUSHs( sv_2mortal( newSViv( c_iRawlen ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_pRawdata, sizeof(char) * c_iRawlen ) ) );
      }


void
mng_getchunk_trns(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk   = (mng_handle) hChunk;
      mng_bool         c_bEmpty   = FALSE;
      mng_bool         c_bGlobal  = FALSE;
      mng_uint8        c_iType    = 0;
      mng_uint32       c_iCount   = 0;
      mng_uint8arr     c_aAlphas;
      mng_uint16       c_iGray    = 0;
      mng_uint16       c_iRed     = 0;
      mng_uint16       c_iGreen   = 0;
      mng_uint16       c_iBlue    = 0;
      mng_uint32       c_iRawlen  = 0;
      mng_uint8arr     c_aRawdata;

   PPCODE:
      c_rv = mng_getchunk_trns(hHandle,c_hChunk,&c_bEmpty,&c_bGlobal,&c_iType,&c_iCount,&c_aAlphas,&c_iGray,&c_iRed,&c_iGreen,&c_iBlue,&c_iRawlen,&c_aRawdata);


      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv ( c_bEmpty    ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_bGlobal   ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iType     ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iCount    ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_aAlphas, sizeof(c_aAlphas) ) ) );  
         XPUSHs( sv_2mortal( newSViv ( c_iGray     ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iRed      ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iGreen    ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iBlue     ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iRawlen   ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_aRawdata, sizeof(c_aRawdata) ) ) ); 
      }


void
mng_getchunk_gama(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk = (mng_handle) hChunk;
      mng_bool         c_bEmpty = FALSE;
      mng_uint32       c_iGamma = 0;

   PPCODE:
      c_rv = mng_getchunk_gama(hHandle,c_hChunk,&c_bEmpty,&c_iGamma);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_bEmpty    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iGamma    ) ) );
      }


void
mng_getchunk_chrm(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk       = (mng_handle) hChunk;
      mng_bool         c_bEmpty       = FALSE;
      mng_uint32       c_iWhitepointx = 0;
      mng_uint32       c_iWhitepointy = 0;
      mng_uint32       c_iRedx        = 0;
      mng_uint32       c_iRedy        = 0;
      mng_uint32       c_iGreenx      = 0;
      mng_uint32       c_iGreeny      = 0;
      mng_uint32       c_iBluex       = 0;
      mng_uint32       c_iBluey       = 0;

   PPCODE:
      c_rv = mng_getchunk_chrm(hHandle,c_hChunk, &c_bEmpty, &c_iWhitepointx, &c_iWhitepointy, &c_iRedx, &c_iRedy, &c_iGreenx, &c_iGreeny, &c_iBluex, &c_iBluey);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_bEmpty       ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iWhitepointx ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iWhitepointy ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iRedx        ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iRedy        ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iGreenx      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iGreeny      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBluex       ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBluey       ) ) );
      }


void
mng_getchunk_srgb(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk           = (mng_handle) hChunk;
      mng_bool         c_bEmpty           = FALSE;
      mng_uint8        c_iRenderingintent = 0;

   PPCODE:
      c_rv = mng_getchunk_srgb(hHandle,c_hChunk, &c_bEmpty, &c_iRenderingintent);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_bEmpty           ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iRenderingintent ) ) );
      }


void
mng_getchunk_iccp(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk       = (mng_handle) hChunk;
      mng_bool         c_bEmpty       = FALSE;
      mng_uint32       c_iNamesize    = 0;
      mng_pchar        c_zName        = NULL;
      mng_uint8        c_iCompression = 0;
      mng_uint32       c_iProfilesize = 0;
      mng_ptr          c_pProfile     = NULL;

   PPCODE:
      c_rv = mng_getchunk_iccp(hHandle,c_hChunk, &c_bEmpty, &c_iNamesize, &c_zName, &c_iCompression, &c_iProfilesize, &c_pProfile);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zName,    c_iNamesize );
         FIX_NULL_PTR( c_pProfile, c_iProfilesize );
         XPUSHs( sv_2mortal( newSViv ( c_bEmpty           ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iNamesize        ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zName, c_iNamesize ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iCompression     ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iProfilesize     ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_pProfile, sizeof(char) * c_iProfilesize ) ) );
      }


void
mng_getchunk_text(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk       = (mng_handle) hChunk;
      mng_uint32       c_iKeywordsize = 0;
      mng_pchar        c_zKeyword     = NULL;
      mng_uint32       c_iTextsize    = 0;
      mng_pchar        c_zText        = NULL;

   PPCODE:
      c_rv = mng_getchunk_text(hHandle,c_hChunk,&c_iKeywordsize,&c_zKeyword,&c_iTextsize,&c_zText);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zKeyword, c_iKeywordsize );
         FIX_NULL_PTR( c_zText,    c_iTextsize    );
         XPUSHs( sv_2mortal( newSViv ( c_iKeywordsize ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zKeyword, c_iKeywordsize ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iTextsize ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zText, c_iTextsize ) ) );
      }


void
mng_getchunk_ztxt(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk        = (mng_handle) hChunk;
      mng_uint32       c_iKeywordsize  = 0;
      mng_pchar        c_zKeyword      = NULL;
      mng_uint8        c_iCompression  = 0;
      mng_uint32       c_iTextsize     = 0;
      mng_pchar        c_zText         = NULL;

   PPCODE:
      c_rv = mng_getchunk_ztxt(hHandle,c_hChunk,&c_iKeywordsize,&c_zKeyword,&c_iCompression,&c_iTextsize,&c_zText);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zKeyword, c_iKeywordsize );
         FIX_NULL_PTR( c_zText,    c_iTextsize    );
         XPUSHs( sv_2mortal( newSViv ( c_iKeywordsize ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zKeyword, c_iKeywordsize ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iCompression  ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iTextsize ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zText, c_iTextsize ) ) );
      }


void
mng_getchunk_itxt(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk              = (mng_handle) hChunk;
      mng_uint32       c_iKeywordsize        = 0;
      mng_pchar        c_zKeyword            = NULL;
      mng_uint8        c_iCompressionflag    = 0;
      mng_uint8        c_iCompressionmethod  = 0;
      mng_uint32       c_iLanguagesize       = 0;
      mng_pchar        c_zLanguage           = NULL;
      mng_uint32       c_iTranslationsize    = 0;
      mng_pchar        c_zTranslation        = NULL;
      mng_uint32       c_iTextsize           = 0;
      mng_pchar        c_zText               = NULL;

   PPCODE:
      c_rv = mng_getchunk_itxt(hHandle,c_hChunk,&c_iKeywordsize,&c_zKeyword,&c_iCompressionflag,&c_iCompressionmethod,&c_iLanguagesize,&c_zLanguage,&c_iTranslationsize,&c_zTranslation,&c_iTextsize,&c_zText);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zKeyword,     c_iKeywordsize     );
         FIX_NULL_PTR( c_zLanguage,    c_iLanguagesize    );
         FIX_NULL_PTR( c_zTranslation, c_iTranslationsize );
         FIX_NULL_PTR( c_zText,        c_iTextsize        );
         XPUSHs( sv_2mortal( newSViv ( c_iKeywordsize                          ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zKeyword,          c_iKeywordsize     ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iCompressionflag                      ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iCompressionmethod                    ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iLanguagesize                         ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zLanguage,         c_iLanguagesize    ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iTranslationsize                      ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zTranslation,      c_iTranslationsize ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iTextsize                             ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zText,             c_iTextsize        ) ) );
      }


void
mng_getchunk_bkgd(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk = (mng_handle) hChunk;
      mng_bool         c_bEmpty = FALSE;
      mng_uint8        c_iType  = 0;
      mng_uint8        c_iIndex = 0;
      mng_uint16       c_iGray  = 0;
      mng_uint16       c_iRed   = 0;
      mng_uint16       c_iGreen = 0;
      mng_uint16       c_iBlue  = 0;

   PPCODE:
      c_rv = mng_getchunk_bkgd(hHandle,c_hChunk,&c_bEmpty,&c_iType,&c_iIndex,&c_iGray,&c_iRed,&c_iGreen,&c_iBlue);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_bEmpty ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iType  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iIndex ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iGray  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iRed   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iGreen ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBlue  ) ) );
      }


void
mng_getchunk_phys(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk = (mng_handle) hChunk;
      mng_bool         c_bEmpty = FALSE;
      mng_uint32       c_iSizex = 0;
      mng_uint32       c_iSizey = 0;
      mng_uint8        c_iUnit  = 0;

   PPCODE:
      c_rv = mng_getchunk_phys(hHandle,c_hChunk,&c_bEmpty,&c_iSizex,&c_iSizey,&c_iUnit);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_bEmpty ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iSizex ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iSizey ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iUnit  ) ) );
      }


void
mng_getchunk_sbit(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk = (mng_handle) hChunk;
      mng_bool         c_bEmpty = FALSE;
      mng_uint8        c_iType  = 0;
      mng_uint8arr4    c_aBits;

   PPCODE:
      c_rv = mng_getchunk_sbit(hHandle,c_hChunk,&c_bEmpty,&c_iType,&c_aBits);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_bEmpty ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iType  ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_aBits, sizeof(c_aBits) ) ) );
      }


void
mng_getchunk_splt(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk        = (mng_handle) hChunk;
      mng_bool         c_bEmpty        = FALSE;
      mng_uint32       c_iNamesize     = 0;
      mng_pchar        c_zName         = NULL;
      mng_uint8        c_iSampledepth  = 0;
      mng_uint32       c_iEntrycount   = 0;
      mng_ptr          c_pEntries      = NULL;

   PPCODE:
      c_rv = mng_getchunk_splt(hHandle,c_hChunk,&c_bEmpty,&c_iNamesize,&c_zName,&c_iSampledepth,&c_iEntrycount,&c_pEntries);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zName,    c_iNamesize   );
         FIX_NULL_PTR( c_pEntries, c_iEntrycount );
         XPUSHs( sv_2mortal( newSViv ( c_bEmpty       ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iNamesize    ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zName, c_iNamesize ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iSampledepth ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iEntrycount  ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_pEntries, sizeof(char) * c_iEntrycount ) ) );
      }


void
mng_getchunk_hist(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk      = (mng_handle) hChunk;
      mng_uint32       c_iEntrycount = 0;
      mng_uint16arr    c_aEntries;

   PPCODE:
      c_rv = mng_getchunk_hist(hHandle,c_hChunk,&c_iEntrycount,&c_aEntries);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iEntrycount ) ) );
         XPUSHs( sv_2mortal( newSVpvn( CHAR_PTR_CAST(c_aEntries), sizeof(c_aEntries) ) ) );
      }


void
mng_getchunk_time(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk  = (mng_handle) hChunk;
      mng_uint16       c_iYear   = 0;
      mng_uint8        c_iMonth  = 0;
      mng_uint8        c_iDay    = 0;
      mng_uint8        c_iHour   = 0;
      mng_uint8        c_iMinute = 0;
      mng_uint8        c_iSecond = 0;

   PPCODE:
      c_rv = mng_getchunk_time(hHandle,c_hChunk,&c_iYear,&c_iMonth,&c_iDay,&c_iHour,&c_iMinute,&c_iSecond);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iYear   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMonth  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iDay    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iHour   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMinute ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iSecond ) ) );
      }


void
mng_getchunk_mhdr(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk      = (mng_handle) hChunk;
      mng_uint32       c_iWidth      = 0;
      mng_uint32       c_iHeight     = 0;
      mng_uint32       c_iTicks      = 0;
      mng_uint32       c_iLayercount = 0;
      mng_uint32       c_iFramecount = 0;
      mng_uint32       c_iPlaytime   = 0;
      mng_uint32       c_iSimplicity = 0;

   PPCODE:
      c_rv = mng_getchunk_mhdr(hHandle,c_hChunk,&c_iWidth,&c_iHeight,&c_iTicks,&c_iLayercount,&c_iFramecount,&c_iPlaytime,&c_iSimplicity);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iWidth      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iHeight     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iTicks      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iLayercount ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iFramecount ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iPlaytime   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iSimplicity ) ) );
      }


void
mng_getchunk_loop(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk       = (mng_handle) hChunk;
      mng_uint8        c_iLevel       = 0;
      mng_uint32       c_iRepeat      = 0;
      mng_uint8        c_iTermination = 0;
      mng_uint32       c_iItermin     = 0;
      mng_uint32       c_iItermax     = 0;
      mng_uint32       c_iCount       = 0;
      mng_uint32p      c_pSignals     = NULL;

   PPCODE:
      c_rv = mng_getchunk_loop(hHandle,c_hChunk,&c_iLevel,&c_iRepeat,&c_iTermination,&c_iItermin,&c_iItermax,&c_iCount,&c_pSignals);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_pSignals, c_iCount );
         XPUSHs( sv_2mortal( newSViv( c_iLevel       ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iRepeat      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iTermination ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iItermin     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iItermax     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iCount       ) ) );
         XPUSHs( sv_2mortal( newSVpvn( CHAR_PTR_CAST(c_pSignals), sizeof(mng_uint32) * c_iCount ) ) );
      }


void
mng_getchunk_endl(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk = (mng_handle) hChunk;
      mng_uint8        c_iLevel = 0;


   PPCODE:
      c_rv = mng_getchunk_endl(hHandle,c_hChunk,&c_iLevel);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iLevel ) ) );
      }


void
mng_getchunk_defi(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk     = (mng_handle) hChunk;
      mng_uint16       c_iObjectid  = 0;
      mng_uint8        c_iDonotshow = 0;
      mng_uint8        c_iConcrete  = 0;
      mng_bool         c_bHasloca   = FALSE;
      mng_int32        c_iXlocation = 0;
      mng_int32        c_iYlocation = 0;
      mng_bool         c_bHasclip   = FALSE;
      mng_int32        c_iLeftcb    = 0;
      mng_int32        c_iRightcb   = 0;
      mng_int32        c_iTopcb     = 0;
      mng_int32        c_iBottomcb  = 0;

   PPCODE:
      c_rv = mng_getchunk_defi(hHandle,c_hChunk,&c_iObjectid,&c_iDonotshow,&c_iConcrete,&c_bHasloca,&c_iXlocation,&c_iYlocation,&c_bHasclip,&c_iLeftcb,&c_iRightcb,&c_iTopcb,&c_iBottomcb);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iObjectid  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iDonotshow ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iConcrete  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_bHasloca   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iXlocation ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iYlocation ) ) );
         XPUSHs( sv_2mortal( newSViv( c_bHasclip   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iLeftcb    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iRightcb   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iTopcb     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBottomcb  ) ) );
      }


void
mng_getchunk_basi(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk       = (mng_handle) hChunk;
      mng_uint32       c_iWidth       = 0;
      mng_uint32       c_iHeight      = 0;
      mng_uint8        c_iBitdepth    = 0;
      mng_uint8        c_iColortype   = 0;
      mng_uint8        c_iCompression = 0;
      mng_uint8        c_iFilter      = 0;
      mng_uint8        c_iInterlace   = 0;
      mng_uint16       c_iRed         = 0;
      mng_uint16       c_iGreen       = 0;
      mng_uint16       c_iBlue        = 0;
      mng_uint16       c_iAlpha       = 0;
      mng_uint8        c_iViewable    = 0;

   PPCODE:
      c_rv = mng_getchunk_basi(hHandle,c_hChunk,&c_iWidth,&c_iHeight,&c_iBitdepth,&c_iColortype,&c_iCompression,&c_iFilter,&c_iInterlace,&c_iRed,&c_iGreen,&c_iBlue,&c_iAlpha,&c_iViewable);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iWidth       ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iHeight      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBitdepth    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iColortype   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iCompression ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iFilter      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iInterlace   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iRed         ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iGreen       ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBlue        ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iAlpha       ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iViewable    ) ) );
      }


void
mng_getchunk_clon(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk        = (mng_handle) hChunk;
      mng_uint16       c_iSourceid     = 0;
      mng_uint16       c_iCloneid      = 0;
      mng_uint8        c_iClonetype    = 0;
      mng_uint8        c_iDonotshow    = 0;
      mng_uint8        c_iConcrete     = 0;
      mng_bool         c_bHasloca      = FALSE;
      mng_uint8        c_iLocationtype = 0;
      mng_int32        c_iLocationx    = 0;
      mng_int32        c_iLocationy    = 0;

   PPCODE:
      c_rv = mng_getchunk_clon(hHandle,c_hChunk,&c_iSourceid,&c_iCloneid,&c_iClonetype,&c_iDonotshow,&c_iConcrete,&c_bHasloca,&c_iLocationtype,&c_iLocationx,&c_iLocationy);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iSourceid     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iCloneid      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iClonetype    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iDonotshow    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iConcrete     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_bHasloca      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iLocationtype ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iLocationx    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iLocationy    ) ) );
      }


void
mng_getchunk_past(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk      = (mng_handle) hChunk;
      mng_uint16       c_iDestid     = 0;
      mng_uint8        c_iTargettype = 0;
      mng_int32        c_iTargetx    = 0;
      mng_int32        c_iTargety    = 0;
      mng_uint32       c_iCount      = 0;

   PPCODE:
      c_rv = mng_getchunk_past(hHandle,c_hChunk,&c_iDestid,&c_iTargettype,&c_iTargetx,&c_iTargety,&c_iCount);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iDestid     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iTargettype ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iTargetx    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iTargety    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iCount      ) ) );
      }


void
mng_getchunk_past_src(hHandle,hChunk,iEntry)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   mng_uint32       iEntry
   PROTOTYPE: $$$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk        = (mng_handle) hChunk;
      mng_uint16       c_iSourceid     = 0;
      mng_uint8        c_iComposition  = 0;
      mng_uint8        c_iOrientation  = 0;
      mng_uint8        c_iOffsettype   = 0;
      mng_int32        c_iOffsetx      = 0;
      mng_int32        c_iOffsety      = 0;
      mng_uint8        c_iBoundarytype = 0;
      mng_int32        c_iBoundaryl    = 0;
      mng_int32        c_iBoundaryr    = 0;
      mng_int32        c_iBoundaryt    = 0;
      mng_int32        c_iBoundaryb    = 0;

   PPCODE:
      c_rv = mng_getchunk_past_src(hHandle,c_hChunk,iEntry,&c_iSourceid,&c_iComposition,&c_iOrientation,&c_iOffsettype,&c_iOffsetx,&c_iOffsety,&c_iBoundarytype,&c_iBoundaryl,&c_iBoundaryr,&c_iBoundaryt,&c_iBoundaryb);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iComposition  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iOrientation  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iOffsettype   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iOffsetx      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iOffsety      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBoundarytype ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBoundaryl    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBoundaryr    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBoundaryt    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBoundaryb    ) ) );
      }


void
mng_getchunk_disc(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk     = (mng_handle) hChunk;
      mng_uint32       c_iCount     = 0;
      mng_uint16p      c_pObjectids = NULL;

   PPCODE:
      c_rv = mng_getchunk_disc(hHandle,c_hChunk,&c_iCount,&c_pObjectids);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_pObjectids, c_iCount );
         XPUSHs( sv_2mortal( newSViv( c_iCount     ) ) );
         XPUSHs( sv_2mortal( newSVpvn( CHAR_PTR_CAST(c_pObjectids), sizeof(mng_uint16) * c_iCount ) ) );
      }


void
mng_getchunk_back(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk     = (mng_handle) hChunk;
      mng_uint16       c_iRed       = 0;
      mng_uint16       c_iGreen     = 0;
      mng_uint16       c_iBlue      = 0;
      mng_uint8        c_iMandatory = 0;
      mng_uint16       c_iImageid   = 0;
      mng_uint8        c_iTile      = 0;

   PPCODE:
      c_rv = mng_getchunk_back(hHandle,c_hChunk,&c_iRed,&c_iGreen,&c_iBlue,&c_iMandatory,&c_iImageid,&c_iTile);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iRed       ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iGreen     ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBlue      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMandatory ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iImageid   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iTile      ) ) );
      }


void
mng_getchunk_fram(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk          = (mng_handle) hChunk;
      mng_bool         c_bEmpty          = FALSE;
      mng_uint8        c_iMode           = 0;
      mng_uint32       c_iNamesize       = 0;
      mng_pchar        c_zName           = NULL;
      mng_uint8        c_iChangedelay    = 0;
      mng_uint8        c_iChangetimeout  = 0;
      mng_uint8        c_iChangeclipping = 0;
      mng_uint8        c_iChangesyncid   = 0;
      mng_uint32       c_iDelay          = 0;
      mng_uint32       c_iTimeout        = 0;
      mng_uint8        c_iBoundarytype   = 0;
      mng_int32        c_iBoundaryl      = 0;
      mng_int32        c_iBoundaryr      = 0;
      mng_int32        c_iBoundaryt      = 0;
      mng_int32        c_iBoundaryb      = 0;
      mng_uint32       c_iCount          = 0;
      mng_uint32p      c_pSyncids        = NULL;

   PPCODE:
      c_rv = mng_getchunk_fram(hHandle,c_hChunk,&c_bEmpty,&c_iMode,&c_iNamesize,&c_zName,&c_iChangedelay,&c_iChangetimeout,&c_iChangeclipping,&c_iChangesyncid,&c_iDelay,&c_iTimeout,&c_iBoundarytype,&c_iBoundaryl,&c_iBoundaryr,&c_iBoundaryt,&c_iBoundaryb,&c_iCount,&c_pSyncids);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zName,    c_iNamesize );
         FIX_NULL_PTR( c_pSyncids, c_iCount    );
         XPUSHs( sv_2mortal( newSViv ( c_bEmpty          ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iMode           ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iNamesize       ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zName, c_iNamesize ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iChangedelay    ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iChangetimeout  ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iChangeclipping ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iChangesyncid   ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iDelay          ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iTimeout        ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iBoundarytype   ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iBoundaryl      ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iBoundaryr      ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iBoundaryt      ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iBoundaryb      ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iCount          ) ) );
         XPUSHs( sv_2mortal( newSVpvn( CHAR_PTR_CAST(c_pSyncids), sizeof(mng_uint32) * c_iCount ) ) );
      }


void
mng_getchunk_move(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk    = (mng_handle) hChunk;
      mng_uint16       c_iFirstid  = 0;
      mng_uint16       c_iLastid   = 0;
      mng_uint8        c_iMovetype = 0;
      mng_int32        c_iMovex    = 0;
      mng_int32        c_iMovey    = 0;

   PPCODE:
      c_rv = mng_getchunk_move(hHandle,c_hChunk,&c_iFirstid,&c_iLastid,&c_iMovetype,&c_iMovex,&c_iMovey);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iFirstid  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iLastid   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMovetype ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMovex    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMovey    ) ) );
      }


void
mng_getchunk_clip(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk    = (mng_handle) hChunk;
      mng_uint16       c_iFirstid  = 0;
      mng_uint16       c_iLastid   = 0;
      mng_uint8        c_iCliptype = 0;
      mng_int32        c_iClipl    = 0;
      mng_int32        c_iClipr    = 0;
      mng_int32        c_iClipt    = 0;
      mng_int32        c_iClipb    = 0;


   PPCODE:
      c_rv = mng_getchunk_clip(hHandle,c_hChunk,&c_iFirstid,&c_iLastid,&c_iCliptype,&c_iClipl,&c_iClipr,&c_iClipt,&c_iClipb);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iFirstid  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iLastid   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iCliptype ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iClipl    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iClipr    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iClipt    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iClipb    ) ) );
      }


void
mng_getchunk_show(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk   = (mng_handle) hChunk;
      mng_bool         c_bEmpty   = FALSE;
      mng_uint16       c_iFirstid = 0;
      mng_uint16       c_iLastid  = 0;
      mng_uint8        c_iMode    = 0;

   PPCODE:
      c_rv = mng_getchunk_show(hHandle,c_hChunk,&c_bEmpty,&c_iFirstid,&c_iLastid,&c_iMode);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_bEmpty   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iFirstid ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iLastid  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMode    ) ) );
      }


void
mng_getchunk_term(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk      = (mng_handle) hChunk;
      mng_uint8        c_iTermaction = 0;
      mng_uint8        c_iIteraction = 0;
      mng_uint32       c_iDelay      = 0;
      mng_uint32       c_iItermax    = 0;

   PPCODE:
      c_rv = mng_getchunk_term(hHandle,c_hChunk,&c_iTermaction,&c_iIteraction,&c_iDelay,&c_iItermax);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iTermaction ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iIteraction ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iDelay      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iItermax    ) ) );
      }


void
mng_getchunk_save(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk      = (mng_handle) hChunk;
      mng_bool         c_bEmpty      = FALSE;
      mng_uint8        c_iOffsettype = 0;
      mng_uint32       c_iCount      = 0;

   PPCODE:
      c_rv = mng_getchunk_save(hHandle,c_hChunk,&c_bEmpty,&c_iOffsettype,&c_iCount);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_bEmpty      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iOffsettype ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iCount      ) ) );
      }


void
mng_getchunk_save_entry(hHandle,hChunk,iEntry)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   mng_uint32       iEntry;
   PROTOTYPE: $$$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk      = (mng_handle) hChunk;
      mng_uint8        c_iEntrytype  = 0;
      mng_uint32arr2   c_aiOffset;
      mng_uint32arr2   c_aiStarttime;
      mng_uint32       c_iLayernr    = 0;
      mng_uint32       c_iFramenr    = 0;
      mng_uint32       c_iNamesize   = 0;
      mng_pchar        c_zName       = NULL;

   PPCODE:
      c_rv = mng_getchunk_save_entry(hHandle,c_hChunk,iEntry,&c_iEntrytype,&c_aiOffset,&c_aiStarttime,&c_iLayernr,&c_iFramenr,&c_iNamesize,&c_zName);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zName, c_iNamesize );
         XPUSHs( sv_2mortal( newSVpvn( CHAR_PTR_CAST(c_aiOffset),    sizeof(c_aiOffset)    ) ) );
         XPUSHs( sv_2mortal( newSVpvn( CHAR_PTR_CAST(c_aiStarttime), sizeof(c_aiStarttime) ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iLayernr   ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iFramenr   ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iNamesize  ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zName, c_iNamesize ) ) );
      }


void
mng_getchunk_seek(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk    = (mng_handle) hChunk;
      mng_uint32       c_iNamesize = 0;
      mng_pchar        c_zName     = NULL;

   PPCODE:
      c_rv = mng_getchunk_seek(hHandle,c_hChunk,&c_iNamesize,&c_zName);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zName, c_iNamesize );
         XPUSHs( sv_2mortal( newSViv ( c_iNamesize ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zName, c_iNamesize ) ) );
      }


void
mng_getchunk_expi(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk      = (mng_handle) hChunk;
      mng_uint16       c_iSnapshotid = 0;
      mng_uint32       c_iNamesize   = 0;
      mng_pchar        c_zName       = NULL;

   PPCODE:
      c_rv = mng_getchunk_expi(hHandle,c_hChunk,&c_iSnapshotid,&c_iNamesize,&c_zName);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zName, c_iNamesize );
         XPUSHs( sv_2mortal( newSViv ( c_iSnapshotid ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iNamesize   ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zName, c_iNamesize ) ) );
      }


void
mng_getchunk_fpri(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk     = (mng_handle) hChunk;
      mng_uint8        c_iDeltatype = 0;
      mng_uint8        c_iPriority  = 0;

   PPCODE:
      c_rv = mng_getchunk_fpri(hHandle,c_hChunk,&c_iDeltatype,&c_iPriority);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iDeltatype ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iPriority  ) ) );
      }


void
mng_getchunk_need(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk        = (mng_handle) hChunk;
      mng_uint32       c_iKeywordssize = 0;
      mng_pchar        c_zKeywords     = NULL;

   PPCODE:
      c_rv = mng_getchunk_need(hHandle,c_hChunk,&c_iKeywordssize,&c_zKeywords);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zKeywords, c_iKeywordssize );
         XPUSHs( sv_2mortal( newSViv ( c_iKeywordssize ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zKeywords, c_iKeywordssize ) ) );
      }


void
mng_getchunk_phyg(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk = (mng_handle) hChunk;
      mng_bool         c_bEmpty = FALSE;
      mng_uint32       c_iSizex = 0;
      mng_uint32       c_iSizey = 0;
      mng_uint8        c_iUnit  = 0;

   PPCODE:
      c_rv = mng_getchunk_phyg(hHandle,c_hChunk,&c_bEmpty,&c_iSizex,&c_iSizey,&c_iUnit);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_bEmpty ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iSizex ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iSizey ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iUnit  ) ) );
      }


void
mng_getchunk_jhdr(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk            = (mng_handle) hChunk;
      mng_uint32       c_iWidth            = 0;
      mng_uint32       c_iHeight           = 0;
      mng_uint8        c_iColortype        = 0;
      mng_uint8        c_iImagesampledepth = 0;
      mng_uint8        c_iImagecompression = 0;
      mng_uint8        c_iImageinterlace   = 0;
      mng_uint8        c_iAlphasampledepth = 0;
      mng_uint8        c_iAlphacompression = 0;
      mng_uint8        c_iAlphafilter      = 0;
      mng_uint8        c_iAlphainterlace   = 0;

   PPCODE:
      c_rv = mng_getchunk_jhdr(hHandle,c_hChunk,&c_iWidth,&c_iHeight,&c_iColortype,&c_iImagesampledepth,&c_iImagecompression,&c_iImageinterlace,&c_iAlphasampledepth,&c_iAlphacompression,&c_iAlphafilter,&c_iAlphainterlace);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iWidth            ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iHeight           ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iColortype        ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iImagesampledepth ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iImagecompression ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iImageinterlace   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iAlphasampledepth ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iAlphacompression ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iAlphafilter      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iAlphainterlace   ) ) );
      }


void
mng_getchunk_jdat(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk   = (mng_handle) hChunk;
      mng_uint32       c_iRawlen  = 0;
      mng_ptr          c_pRawdata = NULL;

   PPCODE:
      c_rv = mng_getchunk_jdat(hHandle,c_hChunk,&c_iRawlen,&c_pRawdata);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_pRawdata, c_iRawlen );
         XPUSHs( sv_2mortal( newSViv( c_iRawlen  ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_pRawdata, sizeof(char) * c_iRawlen ) ) );
      }


void
mng_getchunk_dhdr(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk       = (mng_handle) hChunk;
      mng_uint16       c_iObjectid    = 0;
      mng_uint8        c_iImagetype   = 0;
      mng_uint8        c_iDeltatype   = 0;
      mng_uint32       c_iBlockwidth  = 0;
      mng_uint32       c_iBlockheight = 0;
      mng_uint32       c_iBlockx      = 0;
      mng_uint32       c_iBlocky      = 0;

   PPCODE:
      c_rv = mng_getchunk_dhdr(hHandle,c_hChunk,&c_iObjectid,&c_iImagetype,&c_iDeltatype,&c_iBlockwidth,&c_iBlockheight,&c_iBlockx,&c_iBlocky);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iObjectid    ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iImagetype   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iDeltatype   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBlockwidth  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBlockheight ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBlockx      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBlocky      ) ) );
      }


void
mng_getchunk_prom(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk       = (mng_handle) hChunk;
      mng_uint8        c_iColortype   = 0;
      mng_uint8        c_iSampledepth = 0;
      mng_uint8        c_iFilltype    = 0;

   PPCODE:
      c_rv = mng_getchunk_prom(hHandle,c_hChunk,&c_iColortype,&c_iSampledepth,&c_iFilltype);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iColortype   ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iSampledepth ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iFilltype    ) ) );
      }


void
mng_getchunk_pplt(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk = (mng_handle) hChunk;
      mng_uint32       c_iCount = 0;

   PPCODE:
      c_rv = mng_getchunk_pplt(hHandle,c_hChunk,&c_iCount);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iCount ) ) );
      }


void mng_getchunk_pplt_entry(hHandle,hChunk,iEntry)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   mng_uint32       iEntry;
   PROTOTYPE: $$$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk = (mng_handle) hChunk;
      mng_uint16       c_iRed   = 0;
      mng_uint16       c_iGreen = 0;
      mng_uint16       c_iBlue  = 0;
      mng_uint16       c_iAlpha = 0;
      mng_bool         c_bUsed  = FALSE;

   PPCODE:
      c_rv = mng_getchunk_pplt_entry(hHandle,c_hChunk,iEntry,&c_iRed,&c_iGreen,&c_iBlue,&c_iAlpha,&c_bUsed);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iGreen ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iBlue  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iAlpha ) ) );
         XPUSHs( sv_2mortal( newSViv( c_bUsed  ) ) );
      }


void mng_getchunk_drop(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk      = (mng_handle) hChunk;
      mng_uint32       c_iCount      = 0;
      mng_chunkidp     c_pChunknames = NULL;

   PPCODE:
      c_rv = mng_getchunk_drop(hHandle,c_hChunk,&c_iCount,&c_pChunknames);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_pChunknames, c_iCount );
         XPUSHs( sv_2mortal( newSViv( c_iCount ) ) );
         XPUSHs( sv_2mortal( newSVpvn( CHAR_PTR_CAST(c_pChunknames), sizeof(mng_chunkid) * c_iCount ) ) );
      }


void mng_getchunk_dbyk(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk        = (mng_handle) hChunk;
      mng_chunkid      c_iChunkname    = 0;
      mng_uint8        c_iPolarity     = 0;
      mng_uint32       c_iKeywordssize = 0;
      mng_pchar        c_zKeywords     = NULL;

   PPCODE:
      c_rv = mng_getchunk_dbyk(hHandle,c_hChunk,&c_iChunkname,&c_iPolarity,&c_iKeywordssize,&c_zKeywords);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_zKeywords, c_iKeywordssize );
         XPUSHs( sv_2mortal( newSViv ( c_iChunkname    ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iPolarity     ) ) );
         XPUSHs( sv_2mortal( newSViv ( c_iKeywordssize ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_zKeywords, c_iKeywordssize ) ) );
      }


void mng_getchunk_ordr(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk = (mng_handle) hChunk;
      mng_uint32       c_iCount = 0;

   PPCODE:
      c_rv = mng_getchunk_ordr(hHandle,c_hChunk,&c_iCount);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iCount ) ) );
      }


void mng_getchunk_ordr_entry(hHandle,hChunk,iEntry)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   mng_uint32       iEntry;
   PROTOTYPE: $$$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk     = (mng_handle) hChunk;
      mng_chunkid      c_iChunkname = 0;
      mng_uint8        c_iOrdertype = 0;

   PPCODE:
      c_rv = mng_getchunk_ordr_entry(hHandle,c_hChunk,iEntry,&c_iChunkname,&c_iOrdertype);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iOrdertype ) ) );
      }


void mng_getchunk_magn(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk   = (mng_handle) hChunk;
      mng_uint16       c_iFirstid = 0;
      mng_uint16       c_iLastid  = 0;
      mng_uint16       c_iMethodX = 0;
      mng_uint16       c_iMX      = 0;
      mng_uint16       c_iMY      = 0;
      mng_uint16       c_iML      = 0;
      mng_uint16       c_iMR      = 0;
      mng_uint16       c_iMT      = 0;
      mng_uint16       c_iMB      = 0;
      mng_uint16       c_iMethodY = 0;

   PPCODE:
      c_rv = mng_getchunk_magn(hHandle,c_hChunk,&c_iFirstid,&c_iLastid,&c_iMethodX,&c_iMX,&c_iMY,&c_iML,&c_iMR,&c_iMT,&c_iMB,&c_iMethodY);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         XPUSHs( sv_2mortal( newSViv( c_iFirstid ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iLastid  ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMethodX ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMX      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMY      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iML      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMR      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMT      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMB      ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iMethodY ) ) );
      }


void mng_getchunk_unknown(hHandle,hChunk)
   mng_handle       hHandle
   mng_chunkhandle  hChunk
   PROTOTYPE: $$
   PREINIT:
      mng_retcode      c_rv;
      mng_handle       c_hChunk     = (mng_handle) hChunk;
      mng_chunkid      c_iChunkname = 0;
      mng_uint32       c_iRawlen    = 0;
      mng_ptr          c_pRawdata   = NULL;

   PPCODE:
      c_rv = mng_getchunk_unknown(hHandle,c_hChunk,&c_iChunkname,&c_iRawlen,&c_pRawdata);

      XPUSHs( sv_2mortal( newSViv( c_rv ) ) );
      if ( c_rv == MNG_NOERROR )
      {
         FIX_NULL_PTR( c_pRawdata, c_iRawlen );
         XPUSHs( sv_2mortal( newSViv( c_iChunkname ) ) );
         XPUSHs( sv_2mortal( newSViv( c_iRawlen    ) ) );
         XPUSHs( sv_2mortal( newSVpvn( c_pRawdata, sizeof(char) * c_iRawlen ) ) );
      }



# ------------------------------------------------------------
# ---------- mng_putchunk_* functions
# ------------------------------------------------------------


mng_retcode
mng_putchunk_ihdr(hHandle,iWidth,iHeight,iBitdepth,iColortype,iCompression,iFilter,iInterlace)
   mng_handle       hHandle
   mng_uint32       iWidth
   mng_uint32       iHeight
   mng_uint8        iBitdepth
   mng_uint8        iColortype
   mng_uint8        iCompression
   mng_uint8        iFilter
   mng_uint8        iInterlace
   PROTOTYPE: $$$$$$$$


mng_retcode
mng_putchunk_plte(hHandle,iCount,aPalette)
   mng_handle       hHandle
   mng_uint32       iCount
   mng_palette8ep   aPalette
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_idat(hHandle,iRawlen,pRawdata)
   mng_handle       hHandle
   mng_uint32       iRawlen
   mng_ptr          pRawdata
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_iend(hHandle)
   mng_handle       hHandle
   PROTOTYPE: $


mng_retcode
mng_putchunk_trns(hHandle,bEmpty,bGlobal,iType,iCount,aAlphas,iGray,iRed,iGreen,iBlue,iRawlen,aRawdata)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_bool         bGlobal
   mng_uint8        iType
   mng_uint32       iCount
   mng_uint8*       aAlphas
   mng_uint16       iGray
   mng_uint16       iRed
   mng_uint16       iGreen
   mng_uint16       iBlue
   mng_uint32       iRawlen
   mng_uint8*       aRawdata
   PROTOTYPE: $$$$$$$$$$$$


mng_retcode
mng_putchunk_gama(hHandle,bEmpty,iGamma)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint32       iGamma
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_chrm(hHandle,bEmpty,iWhitepointx,iWhitepointy,iRedx,iRedy,iGreenx,iGreeny,iBluex,iBluey)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint32       iWhitepointx
   mng_uint32       iWhitepointy
   mng_uint32       iRedx
   mng_uint32       iRedy
   mng_uint32       iGreenx
   mng_uint32       iGreeny
   mng_uint32       iBluex
   mng_uint32       iBluey
   PROTOTYPE: $$$$$$$$$$


mng_retcode
mng_putchunk_srgb(hHandle,bEmpty,iRenderingintent)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint8        iRenderingintent
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_iccp(hHandle,bEmpty,iNamesize,zName,iCompression,iProfilesize,pProfile)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint32       iNamesize
   mng_pchar        zName
   mng_uint8        iCompression
   mng_uint32       iProfilesize
   mng_ptr          pProfile
   PROTOTYPE: $$$$$$$


mng_retcode
mng_putchunk_text(hHandle,iKeywordsize,zKeyword,iTextsize,zText)
   mng_handle       hHandle
   mng_uint32       iKeywordsize
   mng_pchar        zKeyword
   mng_uint32       iTextsize
   mng_pchar        zText
   PROTOTYPE: $$$$$


mng_retcode
mng_putchunk_ztxt(hHandle,iKeywordsize,zKeyword,iCompression,iTextsize,zText)
   mng_handle       hHandle
   mng_uint32       iKeywordsize
   mng_pchar        zKeyword
   mng_uint8        iCompression
   mng_uint32       iTextsize
   mng_pchar        zText
   PROTOTYPE: $$$$$$


mng_retcode
mng_putchunk_itxt(hHandle,iKeywordsize,zKeyword,iCompressionflag,iCompressionmethod,iLanguagesize,zLanguage,iTranslationsize,zTranslation,iTextsize,zText)
   mng_handle       hHandle
   mng_uint32       iKeywordsize
   mng_pchar        zKeyword
   mng_uint8        iCompressionflag
   mng_uint8        iCompressionmethod
   mng_uint32       iLanguagesize
   mng_pchar        zLanguage
   mng_uint32       iTranslationsize
   mng_pchar        zTranslation
   mng_uint32       iTextsize
   mng_pchar        zText
   PROTOTYPE: $$$$$$$$$$$


mng_retcode
mng_putchunk_bkgd(hHandle,bEmpty,iType,iIndex,iGray,iRed,iGreen,iBlue)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint8        iType
   mng_uint8        iIndex
   mng_uint16       iGray
   mng_uint16       iRed
   mng_uint16       iGreen
   mng_uint16       iBlue
   PROTOTYPE: $$$$$$$$


mng_retcode
mng_putchunk_phys(hHandle,bEmpty,iSizex,iSizey,iUnit)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint32       iSizex
   mng_uint32       iSizey
   mng_uint8        iUnit
   PROTOTYPE: $$$$$


mng_retcode
mng_putchunk_sbit(hHandle,bEmpty,iType,aBits)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint8        iType
   mng_uint8*       aBits
   PROTOTYPE: $$$$


mng_retcode
mng_putchunk_splt(hHandle,bEmpty,iNamesize,zName,iSampledepth,iEntrycount,pEntries)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint32       iNamesize
   mng_pchar        zName
   mng_uint8        iSampledepth
   mng_uint32       iEntrycount
   mng_ptr          pEntries
   PROTOTYPE: $$$$$$$


mng_retcode
mng_putchunk_hist(hHandle,iEntrycount,aEntries)
   mng_handle       hHandle
   mng_uint32       iEntrycount
   mng_uint16*      aEntries
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_time(hHandle,iYear,iMonth,iDay,iHour,iMinute,iSecond)
   mng_handle       hHandle
   mng_uint16       iYear
   mng_uint8        iMonth
   mng_uint8        iDay
   mng_uint8        iHour
   mng_uint8        iMinute
   mng_uint8        iSecond
   PROTOTYPE: $$$$$$$


mng_retcode
mng_putchunk_mhdr(hHandle,iWidth,iHeight,iTicks,iLayercount,iFramecount,iPlaytime,iSimplicity)
   mng_handle       hHandle
   mng_uint32       iWidth
   mng_uint32       iHeight
   mng_uint32       iTicks
   mng_uint32       iLayercount
   mng_uint32       iFramecount
   mng_uint32       iPlaytime
   mng_uint32       iSimplicity
   PROTOTYPE: $$$$$$$$


mng_retcode
mng_putchunk_mend(hHandle)
   mng_handle       hHandle
   PROTOTYPE: $


mng_retcode
mng_putchunk_loop(hHandle,iLevel,iRepeat,iTermination,iItermin,iItermax,iCount,pSignals)
   mng_handle       hHandle
   mng_uint8        iLevel
   mng_uint32       iRepeat
   mng_uint8        iTermination
   mng_uint32       iItermin
   mng_uint32       iItermax
   mng_uint32       iCount
   mng_uint32p      pSignals
   PROTOTYPE: $$$$$$$$


mng_retcode
mng_putchunk_endl(hHandle,iLevel)
   mng_handle       hHandle
   mng_uint8        iLevel
   PROTOTYPE: $$


mng_retcode
mng_putchunk_defi(hHandle,iObjectid,iDonotshow,iConcrete,bHasloca,iXlocation,iYlocation,bHasclip,iLeftcb,iRightcb,iTopcb,iBottomcb)
   mng_handle       hHandle
   mng_uint16       iObjectid
   mng_uint8        iDonotshow
   mng_uint8        iConcrete
   mng_bool         bHasloca
   mng_int32        iXlocation
   mng_int32        iYlocation
   mng_bool         bHasclip
   mng_int32        iLeftcb
   mng_int32        iRightcb
   mng_int32        iTopcb
   mng_int32        iBottomcb
   PROTOTYPE: $$$$$$$$$$$$


mng_retcode
mng_putchunk_basi(hHandle,iWidth,iHeight,iBitdepth,iColortype,iCompression,iFilter,iInterlace,iRed,iGreen,iBlue,iAlpha,iViewable)
   mng_handle       hHandle
   mng_uint32       iWidth
   mng_uint32       iHeight
   mng_uint8        iBitdepth
   mng_uint8        iColortype
   mng_uint8        iCompression
   mng_uint8        iFilter
   mng_uint8        iInterlace
   mng_uint16       iRed
   mng_uint16       iGreen
   mng_uint16       iBlue
   mng_uint16       iAlpha
   mng_uint8        iViewable
   PROTOTYPE: $$$$$$$$$$$$$


mng_retcode
mng_putchunk_clon(hHandle,iSourceid,iCloneid,iClonetype,iDonotshow,iConcrete,bHasloca,iLocationtype,iLocationx,iLocationy)
   mng_handle       hHandle
   mng_uint16       iSourceid
   mng_uint16       iCloneid
   mng_uint8        iClonetype
   mng_uint8        iDonotshow
   mng_uint8        iConcrete
   mng_bool         bHasloca
   mng_uint8        iLocationtype
   mng_int32        iLocationx
   mng_int32        iLocationy
   PROTOTYPE: $$$$$$$$$$


mng_retcode
mng_putchunk_past(hHandle,iDestid,iTargettype,iTargetx,iTargety,iCount)
   mng_handle       hHandle
   mng_uint16       iDestid
   mng_uint8        iTargettype
   mng_int32        iTargetx
   mng_int32        iTargety
   mng_uint32       iCount
   PROTOTYPE: $$$$$$


mng_retcode
mng_putchunk_past_src(hHandle,iEntry,iSourceid,iComposition,iOrientation,iOffsettype,iOffsetx,iOffsety,iBoundarytype,iBoundaryl,iBoundaryr,iBoundaryt,iBoundaryb)
   mng_handle       hHandle
   mng_uint32       iEntry
   mng_uint16       iSourceid
   mng_uint8        iComposition
   mng_uint8        iOrientation
   mng_uint8        iOffsettype
   mng_int32        iOffsetx
   mng_int32        iOffsety
   mng_uint8        iBoundarytype
   mng_int32        iBoundaryl
   mng_int32        iBoundaryr
   mng_int32        iBoundaryt
   mng_int32        iBoundaryb
   PROTOTYPE: $$$$$$$$$$$$$


mng_retcode
mng_putchunk_disc(hHandle,iCount,pObjectids)
   mng_handle       hHandle
   mng_uint32       iCount
   mng_uint16p      pObjectids
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_back(hHandle,iRed,iGreen,iBlue,iMandatory,iImageid,iTile)
   mng_handle       hHandle
   mng_uint16       iRed
   mng_uint16       iGreen
   mng_uint16       iBlue
   mng_uint8        iMandatory
   mng_uint16       iImageid
   mng_uint8        iTile
   PROTOTYPE: $$$$$$$


mng_retcode
mng_putchunk_fram(hHandle,bEmpty,iMode,iNamesize,zName,iChangedelay,iChangetimeout,iChangeclipping,iChangesyncid,iDelay,iTimeout,iBoundarytype,iBoundaryl,iBoundaryr,iBoundaryt,iBoundaryb,iCount,pSyncids)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint8        iMode
   mng_uint32       iNamesize
   mng_pchar        zName
   mng_uint8        iChangedelay
   mng_uint8        iChangetimeout
   mng_uint8        iChangeclipping
   mng_uint8        iChangesyncid
   mng_uint32       iDelay
   mng_uint32       iTimeout
   mng_uint8        iBoundarytype
   mng_int32        iBoundaryl
   mng_int32        iBoundaryr
   mng_int32        iBoundaryt
   mng_int32        iBoundaryb
   mng_uint32       iCount
   mng_uint32p      pSyncids
   PROTOTYPE: $$$$$$$$$$$$$$$$$$


mng_retcode
mng_putchunk_move(hHandle,iFirstid,iLastid,iMovetype,iMovex,iMovey)
   mng_handle       hHandle
   mng_uint16       iFirstid
   mng_uint16       iLastid
   mng_uint8        iMovetype
   mng_int32        iMovex
   mng_int32        iMovey
   PROTOTYPE: $$$$$$


mng_retcode
mng_putchunk_clip(hHandle,iFirstid,iLastid,iCliptype,iClipl,iClipr,iClipt,iClipb)
   mng_handle       hHandle
   mng_uint16       iFirstid
   mng_uint16       iLastid
   mng_uint8        iCliptype
   mng_int32        iClipl
   mng_int32        iClipr
   mng_int32        iClipt
   mng_int32        iClipb
   PROTOTYPE: $$$$$$$$


mng_retcode
mng_putchunk_show(hHandle,bEmpty,iFirstid,iLastid,iMode)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint16       iFirstid
   mng_uint16       iLastid
   mng_uint8        iMode
   PROTOTYPE: $$$$$


mng_retcode
mng_putchunk_term(hHandle,iTermaction,iIteraction,iDelay,iItermax)
   mng_handle       hHandle
   mng_uint8        iTermaction
   mng_uint8        iIteraction
   mng_uint32       iDelay
   mng_uint32       iItermax
   PROTOTYPE: $$$$$


mng_retcode
mng_putchunk_save(hHandle,bEmpty,iOffsettype,iCount)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint8        iOffsettype
   mng_uint32       iCount
   PROTOTYPE: $$$$


mng_retcode
mng_putchunk_save_entry(hHandle,iEntry,iEntrytype,iOffset,iStarttime,iLayernr,iFramenr,iNamesize,zName)
   mng_handle       hHandle
   mng_uint32       iEntry
   mng_uint8        iEntrytype
   mng_uint32*      iOffset
   mng_uint32*      iStarttime
   mng_uint32       iLayernr
   mng_uint32       iFramenr
   mng_uint32       iNamesize
   mng_pchar        zName
   PROTOTYPE: $$$$$$$$$


mng_retcode
mng_putchunk_seek(hHandle,iNamesize,zName)
   mng_handle       hHandle
   mng_uint32       iNamesize
   mng_pchar        zName
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_expi(hHandle,iSnapshotid,iNamesize,zName)
   mng_handle       hHandle
   mng_uint16       iSnapshotid
   mng_uint32       iNamesize
   mng_pchar        zName
   PROTOTYPE: $$$$


mng_retcode
mng_putchunk_fpri(hHandle,iDeltatype,iPriority)
   mng_handle       hHandle
   mng_uint8        iDeltatype
   mng_uint8        iPriority
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_need(hHandle,iKeywordssize,zKeywords)
   mng_handle       hHandle
   mng_uint32       iKeywordssize
   mng_pchar        zKeywords
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_phyg(hHandle,bEmpty,iSizex,iSizey,iUnit)
   mng_handle       hHandle
   mng_bool         bEmpty
   mng_uint32       iSizex
   mng_uint32       iSizey
   mng_uint8        iUnit
   PROTOTYPE: $$$$$


mng_retcode
mng_putchunk_jhdr(hHandle,iWidth,iHeight,iColortype,iImagesampledepth,iImagecompression,iImageinterlace,iAlphasampledepth,iAlphacompression,iAlphafilter,iAlphainterlace)
   mng_handle       hHandle
   mng_uint32       iWidth
   mng_uint32       iHeight
   mng_uint8        iColortype
   mng_uint8        iImagesampledepth
   mng_uint8        iImagecompression
   mng_uint8        iImageinterlace
   mng_uint8        iAlphasampledepth
   mng_uint8        iAlphacompression
   mng_uint8        iAlphafilter
   mng_uint8        iAlphainterlace
   PROTOTYPE: $$$$$$$$$$$


mng_retcode
mng_putchunk_jdat(hHandle,iRawlen,pRawdata)
   mng_handle       hHandle
   mng_uint32       iRawlen
   mng_ptr          pRawdata
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_jsep(hHandle)
   mng_handle       hHandle
   PROTOTYPE: $


mng_retcode
mng_putchunk_dhdr(hHandle,iObjectid,iImagetype,iDeltatype,iBlockwidth,iBlockheight,iBlockx,iBlocky)
   mng_handle       hHandle
   mng_uint16       iObjectid
   mng_uint8        iImagetype
   mng_uint8        iDeltatype
   mng_uint32       iBlockwidth
   mng_uint32       iBlockheight
   mng_uint32       iBlockx
   mng_uint32       iBlocky
   PROTOTYPE: $$$$$$$$


mng_retcode
mng_putchunk_prom(hHandle,iColortype,iSampledepth,iFilltype)
   mng_handle       hHandle
   mng_uint8        iColortype
   mng_uint8        iSampledepth
   mng_uint8        iFilltype
   PROTOTYPE: $$$$


mng_retcode
mng_putchunk_ipng(hHandle)
   mng_handle       hHandle
   PROTOTYPE: $


mng_retcode
mng_putchunk_pplt(hHandle,iCount)
   mng_handle       hHandle
   mng_uint32       iCount
   PROTOTYPE: $$


mng_retcode
mng_putchunk_pplt_entry(hHandle,iEntry,iRed,iGreen,iBlue,iAlpha,bUsed)
   mng_handle       hHandle
   mng_uint32       iEntry
   mng_uint16       iRed
   mng_uint16       iGreen
   mng_uint16       iBlue
   mng_uint16       iAlpha
   mng_bool         bUsed
   PROTOTYPE: $$$$$$$


mng_retcode
mng_putchunk_drop(hHandle,iCount,pChunknames)
   mng_handle       hHandle
   mng_uint32       iCount
   mng_chunkidp     pChunknames
   PROTOTYPE: $$$


mng_retcode
mng_putchunk_dbyk(hHandle,iChunkname,iPolarity,iKeywordssize,zKeywords)
   mng_handle       hHandle
   mng_chunkid      iChunkname
   mng_uint8        iPolarity
   mng_uint32       iKeywordssize
   mng_pchar        zKeywords
   PROTOTYPE: $$$$$


mng_retcode
mng_putchunk_ordr(hHandle,iCount)
   mng_handle       hHandle
   mng_uint32       iCount
   PROTOTYPE: $$


mng_retcode
mng_putchunk_ordr_entry(hHandle,iEntry,iChunkname,iOrdertype)
   mng_handle       hHandle
   mng_uint32       iEntry
   mng_chunkid      iChunkname
   mng_uint8        iOrdertype
   PROTOTYPE: $$$$


mng_retcode
mng_putchunk_magn(hHandle,iFirstid,iLastid,iMethodX,iMX,iMY,iML,iMR,iMT,iMB,iMethodY)
   mng_handle       hHandle
   mng_uint16       iFirstid
   mng_uint16       iLastid
   mng_uint16       iMethodX
   mng_uint16       iMX
   mng_uint16       iMY
   mng_uint16       iML
   mng_uint16       iMR
   mng_uint16       iMT
   mng_uint16       iMB
   mng_uint16       iMethodY
   PROTOTYPE: $$$$$$$$$$$


mng_retcode
mng_putchunk_unknown(hHandle,iChunkname,iRawlen,pRawdata)
   mng_handle       hHandle
   mng_chunkid      iChunkname
   mng_uint32       iRawlen
   mng_ptr          pRawdata
   PROTOTYPE: $$$$


# ------------------------------------------------------------
# ---------- mng_getimgdata_* functions
# ------------------------------------------------------------


mng_retcode
mng_getimgdata_seq(hHandle,iSeqnr,iCanvasstyle,fGetcanvasline)
   mng_handle        hHandle
   mng_uint32        iSeqnr
   mng_uint32        iCanvasstyle
   SV *              fGetcanvasline
   PROTOTYPE: $$$$
   CODE:
      RETVAL = MNG_NOCALLBACK;
      if ( store_cbfn(hHandle,_MNG_GETCANVASLINE_ONESHOT,fGetcanvasline) )
      {
         RETVAL = mng_getimgdata_seq(hHandle,iSeqnr,iCanvasstyle,&_mng_getcanvasline_oneshot);
      }
   OUTPUT:
      RETVAL


mng_retcode
mng_getimgdata_chunkseq(hHandle,iSeqnr,iCanvasstyle,fGetcanvasline)
   mng_handle        hHandle
   mng_uint32        iSeqnr
   mng_uint32        iCanvasstyle
   SV *              fGetcanvasline
   PROTOTYPE: $$$$
   CODE:
      RETVAL = MNG_NOCALLBACK;
      if ( store_cbfn(hHandle,_MNG_GETCANVASLINE_ONESHOT,fGetcanvasline) )
      {
         RETVAL = mng_getimgdata_chunkseq(hHandle,iSeqnr,iCanvasstyle,&_mng_getcanvasline_oneshot);
      }
   OUTPUT:
      RETVAL


mng_retcode
mng_getimgdata_chunk(hHandle,hChunk,iCanvasstyle,fGetcanvasline)
   mng_handle        hHandle
   mng_chunkhandle   hChunk
   mng_uint32        iCanvasstyle
   SV *              fGetcanvasline
   PROTOTYPE: $$$$
   PREINIT:
      mng_handle c_hChunk = (mng_handle) hChunk;
   CODE:
      RETVAL = MNG_NOCALLBACK;
      if ( store_cbfn(hHandle,_MNG_GETCANVASLINE_ONESHOT,fGetcanvasline) )
      {
         RETVAL = mng_getimgdata_chunk(hHandle,c_hChunk,iCanvasstyle,&_mng_getcanvasline_oneshot);
      }
   OUTPUT:
      RETVAL


# ------------------------------------------------------------
# ---------- mng_putimgdata_* functions
# ------------------------------------------------------------


mng_retcode
mng_putimgdata_ihdr(hHandle,iWidth,iHeight,iColortype,iBitdepth,iCompression,iFilter,iInterlace,iCanvasstyle,fGetcanvasline)
   mng_handle        hHandle
   mng_uint32        iWidth
   mng_uint32        iHeight
   mng_uint8         iColortype
   mng_uint8         iBitdepth
   mng_uint8         iCompression
   mng_uint8         iFilter
   mng_uint8         iInterlace
   mng_uint32        iCanvasstyle
   SV *              fGetcanvasline
   PROTOTYPE: $$$$$$$$$$
   CODE:
      RETVAL = MNG_NOCALLBACK;
      if ( store_cbfn(hHandle,_MNG_GETCANVASLINE_ONESHOT,fGetcanvasline) )
      {
         RETVAL = mng_putimgdata_ihdr(hHandle,iWidth,iHeight,iColortype,iBitdepth,iCompression,iFilter,iInterlace,iCanvasstyle,&_mng_getcanvasline_oneshot);
      }
   OUTPUT:
      RETVAL


mng_retcode
mng_putimgdata_jhdr(hHandle,iWidth,iHeight,iColortype,iBitdepth,iCompression,iInterlace,iAlphaBitdepth,iAlphaCompression,iAlphaFilter,iAlphaInterlace,iCanvasstyle,fGetcanvasline)
   mng_handle        hHandle
   mng_uint32        iWidth
   mng_uint32        iHeight
   mng_uint8         iColortype
   mng_uint8         iBitdepth
   mng_uint8         iCompression
   mng_uint8         iInterlace
   mng_uint8         iAlphaBitdepth
   mng_uint8         iAlphaCompression
   mng_uint8         iAlphaFilter
   mng_uint8         iAlphaInterlace
   mng_uint32        iCanvasstyle
   SV *              fGetcanvasline
   PROTOTYPE: $$$$$$$$$$$$$
   CODE:
      RETVAL = MNG_NOCALLBACK;
      if ( store_cbfn(hHandle,_MNG_GETCANVASLINE_ONESHOT,fGetcanvasline) )
      {
         RETVAL = mng_putimgdata_jhdr(hHandle,iWidth,iHeight,iColortype,iBitdepth,iCompression,iInterlace,iAlphaBitdepth,iAlphaCompression,iAlphaFilter,iAlphaInterlace,iCanvasstyle,&_mng_getcanvasline_oneshot);
      }
   OUTPUT:
      RETVAL


# ------------------------------------------------------------
# ---------- misc functions
# ------------------------------------------------------------


mng_retcode
mng_updatemngheader(hHandle,iFramecount,iLayercount,iPlaytime)
   mng_handle        hHandle
   mng_uint32        iFramecount
   mng_uint32        iLayercount
   mng_uint32        iPlaytime
   PROTOTYPE: $$$$


mng_retcode
mng_updatemngsimplicity(hHandle,iSimplicity)
   mng_handle        hHandle
   mng_uint32        iSimplicity
   PROTOTYPE: $$









#===============================================================================
# --------------------------------- TO-DO LIST ----- (todo, to do, to-do) ------
#
# 0.  Check all cases where I construct a newSVpv[n], and make sure
#     that I calculate the length correctly!!!
# 1.  Need to add any appropriate #define protection around functionality
#     that may be compiled out.
# 2.  Need to implement all functionality
# 3.  Implement tests for all functionality
# 4.  Refactor implementation where arrays of ints are returned.
#     Currently, just a buffer is returned, and the PERL user would need to
#     unpack() it (and also know what kind of data was in it!)
#
#===============================================================================
# Done?  ReturnVal   Function                                              notes
#===============================================================================
#                    MNG CONSTANTS RETURNING NON-INTEGER DATA
#===============================================================================
# YES    mng_pchar   MNG_TEXT_TITLE()
# YES    mng_pchar   MNG_TEXT_AUTHOR()
# YES    mng_pchar   MNG_TEXT_DESCRIPTION()
# YES    mng_pchar   MNG_TEXT_COPYRIGHT()
# YES    mng_pchar   MNG_TEXT_CREATIONTIME()
# YES    mng_pchar   MNG_TEXT_SOFTWARE()
# YES    mng_pchar   MNG_TEXT_DISCLAIMER()
# YES    mng_pchar   MNG_TEXT_WARNING()
# YES    mng_pchar   MNG_TEXT_SOURCE()
# YES    mng_pchar   MNG_TEXT_COMMENT()
#===============================================================================
#                    MNG VERSION FUNCTIONS
#===============================================================================
# YES    mng_pchar   mng_version_text()
# YES    mng_uint8   mng_version_so()
# YES    mng_uint8   mng_version_dll()
# YES    mng_uint8   mng_version_major()
# YES    mng_uint8   mng_version_minor()
# YES    mng_uint8   mng_version_release()
#===============================================================================
#                    MNG HIGH-LEVEL INTERFACE FUNCTIONS
#===============================================================================
# YES    mng_handle  mng_initialize(userdata=NULL)
# YES    mng_retcode mng_reset          (hHandle)
# YES    mng_retcode mng_cleanup        (hHandle)
# YES    mng_retcode mng_read           (hHandle)
# YES    mng_retcode mng_read_resume    (hHandle)
# YES    mng_retcode mng_write          (hHandle)
# YES    mng_retcode mng_create         (hHandle)
# YES    mng_retcode mng_readdisplay    (hHandle)
# YES    mng_retcode mng_display        (hHandle)
# YES    mng_retcode mng_display_resume (hHandle)
# YES    mng_retcode mng_display_freeze (hHandle)
# YES    mng_retcode mng_display_reset  (hHandle)
# YES    mng_display_goframe            (hHandle, iFramenr)
# YES    mng_display_golayer            (hHandle, iLayernr)
# YES    mng_display_gotime             (hHandle, iPlaytime)
# YES    <list> mng_getlasterror        (hHandle)
#
# ------- autogenerated functions ('?' means untested) --------
# YES    mng_setcb_memalloc             (hHandle, fProc)
# YES    mng_setcb_memfree              (hHandle, fProc)
# YES    mng_setcb_openstream           (hHandle, fProc)
# YES    mng_setcb_closestream          (hHandle, fProc)
# YES    mng_setcb_readdata             (hHandle, fProc)
# YES    mng_setcb_writedata            (hHandle, fProc)
# YES    mng_setcb_errorproc            (hHandle, fProc)
# YES    mng_setcb_traceproc            (hHandle, fProc)
# YES    mng_setcb_processheader        (hHandle, fProc)
# YES    mng_setcb_processtext          (hHandle, fProc)
# YES    mng_setcb_processsave          (hHandle, fProc)
# YES    mng_setcb_processseek          (hHandle, fProc)
# YES    mng_setcb_processneed          (hHandle, fProc)
# YES    mng_setcb_processmend          (hHandle, fProc)
# YES    mng_setcb_processunknown       (hHandle, fProc)
# YES    mng_setcb_processterm          (hHandle, fProc)
# YES    mng_setcb_getcanvasline        (hHandle, fProc)
# YES    mng_setcb_getbkgdline          (hHandle, fProc)
# YES    mng_setcb_getalphaline         (hHandle, fProc)
# YES    mng_setcb_refresh              (hHandle, fProc)
# YES    mng_setcb_gettickcount         (hHandle, fProc)
# YES    mng_setcb_settimer             (hHandle, fProc)
# YES    mng_setcb_processgamma         (hHandle, fProc)
# YES    mng_setcb_processchroma        (hHandle, fProc)
# YES    mng_setcb_processsrgb          (hHandle, fProc)
# YES    mng_setcb_processiccp          (hHandle, fProc)
# YES    mng_setcb_processarow          (hHandle, fProc)
# YES    mng_getcb_memalloc             (hHandle)
# YES    mng_getcb_memfree              (hHandle)
# YES    mng_getcb_openstream           (hHandle)
# YES    mng_getcb_closestream          (hHandle)
# YES    mng_getcb_readdata             (hHandle)
# YES    mng_getcb_writedata            (hHandle)
# YES    mng_getcb_errorproc            (hHandle)
# YES    mng_getcb_traceproc            (hHandle)
# YES    mng_getcb_processheader        (hHandle)
# YES    mng_getcb_processtext          (hHandle)
# YES    mng_getcb_processsave          (hHandle)
# YES    mng_getcb_processseek          (hHandle)
# YES    mng_getcb_processneed          (hHandle)
# YES    mng_getcb_processunknown       (hHandle)
# YES    mng_getcb_processterm          (hHandle)
# YES    mng_getcb_getcanvasline        (hHandle)
# YES    mng_getcb_getbkgdline          (hHandle)
# YES    mng_getcb_getalphaline         (hHandle)
# YES    mng_getcb_refresh              (hHandle)
# YES    mng_getcb_gettickcount         (hHandle)
# YES    mng_getcb_settimer             (hHandle)
# YES    mng_getcb_processgamma         (hHandle)
# YES    mng_getcb_processchroma        (hHandle)
# YES    mng_getcb_processsrgb          (hHandle)
# YES    mng_getcb_processiccp          (hHandle)
# YES    mng_getcb_processarow          (hHandle)
#
# YES?   mng_set_userdata               (hHandle, pUserdata)
# YES?   mng_set_canvasstyle            (hHandle, iStyle)
# YES?   mng_set_bkgdstyle              (hHandle, iStyle)
# YES?   mng_set_bgcolor                (hHandle, iRed, iGreen, iBlue)
# YES?   mng_set_usebkgd                (hHandle, bUseBKGD)
# YES?   mng_set_storechunks            (hHandle, bStorechunks)
# YES?   mng_set_sectionbreaks          (hHandle, bSectionbreaks)
# YES?   mng_set_cacheplayback          (hHandle, bCacheplayback)
# YES?   mng_set_doprogressive          (hHandle, bDoProgressive)
# YES?   mng_set_srgb                   (hHandle, bIssRGB)
# YES?   mng_set_outputprofile          (hHandle, zFilename)
# YES?   mng_set_outputprofile2         (hHandle, iProfilesize, pProfile)
# YES?   mng_set_outputsrgb             (hHandle)
# YES?   mng_set_srgbprofile            (hHandle, zFilename)
# YES?   mng_set_srgbprofile2           (hHandle, iProfilesize, pProfile)
# YES?   mng_set_srgbimplicit           (hHandle)
# YES?   mng_set_viewgamma              (hHandle, dGamma)
# YES?   mng_set_displaygamma           (hHandle, dGamma)
# YES?   mng_set_dfltimggamma           (hHandle, dGamma)
# YES?   mng_set_viewgammaint           (hHandle, iGamma)
# YES?   mng_set_displaygammaint        (hHandle, iGamma)
# YES?   mng_set_dfltimggammaint        (hHandle, iGamma)
# YES?   mng_set_maxcanvaswidth         (hHandle, iMaxwidth)
# YES?   mng_set_maxcanvasheight        (hHandle, iMaxheight)
# YES?   mng_set_maxcanvassize          (hHandle, iMaxwidth, iMaxheight)
# YES?   mng_set_zlib_level             (hHandle, iZlevel)
# YES?   mng_set_zlib_method            (hHandle, iZmethod)
# YES?   mng_set_zlib_windowbits        (hHandle, iZwindowbits)
# YES?   mng_set_zlib_memlevel          (hHandle, iZmemlevel)
# YES?   mng_set_zlib_strategy          (hHandle, iZstrategy)
# YES?   mng_set_zlib_maxidat           (hHandle, iMaxIDAT)
# YES?   mng_set_jpeg_dctmethod         (hHandle, eJPEGdctmethod)
# YES?   mng_set_jpeg_quality           (hHandle, iJPEGquality)
# YES?   mng_set_jpeg_smoothing         (hHandle, iJPEGsmoothing)
# YES?   mng_set_jpeg_progressive       (hHandle, bJPEGprogressive)
# YES?   mng_set_jpeg_optimized         (hHandle, bJPEGoptimized)
# YES?   mng_set_jpeg_maxjdat           (hHandle, iMaxJDAT)
# YES?   mng_set_suspensionmode         (hHandle, bSuspensionmode)
# YES?   mng_set_speed                  (hHandle, iSpeed)
# YES?   mng_get_userdata               (hHandle)
# YES?   mng_get_sigtype                (hHandle)
# YES?   mng_get_imagetype              (hHandle)
# YES?   mng_get_imagewidth             (hHandle)
# YES?   mng_get_imageheight            (hHandle)
# YES?   mng_get_ticks                  (hHandle)
# YES?   mng_get_framecount             (hHandle)
# YES?   mng_get_layercount             (hHandle)
# YES?   mng_get_playtime               (hHandle)
# YES?   mng_get_simplicity             (hHandle)
# YES?   mng_get_bitdepth               (hHandle)
# YES?   mng_get_colortype              (hHandle)
# YES?   mng_get_compression            (hHandle)
# YES?   mng_get_filter                 (hHandle)
# YES?   mng_get_interlace              (hHandle)
# YES?   mng_get_alphabitdepth          (hHandle)
# YES?   mng_get_alphacompression       (hHandle)
# YES?   mng_get_alphafilter            (hHandle)
# YES?   mng_get_alphainterlace         (hHandle)
# YES?   mng_get_alphadepth             (hHandle)
# YES?   mng_get_refreshpass            (hHandle)
# YES?   mng_get_canvasstyle            (hHandle)
# YES?   mng_get_bkgdstyle              (hHandle)
# YES?   mng_get_bgcolor                (hHandle)
# YES?   mng_get_usebkgd                (hHandle)
# YES?   mng_get_storechunks            (hHandle)
# YES?   mng_get_sectionbreaks          (hHandle)
# YES?   mng_get_cacheplayback          (hHandle)
# YES?   mng_get_doprogressive          (hHandle)
# YES?   mng_get_srgb                   (hHandle)
# YES?   mng_get_viewgamma              (hHandle)
# YES?   mng_get_displaygamma           (hHandle)
# YES?   mng_get_dfltimggamma           (hHandle)
# YES?   mng_get_viewgammaint           (hHandle)
# YES?   mng_get_displaygammaint        (hHandle)
# YES?   mng_get_dfltimggammaint        (hHandle)
# YES?   mng_get_maxcanvaswidth         (hHandle)
# YES?   mng_get_maxcanvasheight        (hHandle)
# YES?   mng_get_zlib_level             (hHandle)
# YES?   mng_get_zlib_method            (hHandle)
# YES?   mng_get_zlib_windowbits        (hHandle)
# YES?   mng_get_zlib_memlevel          (hHandle)
# YES?   mng_get_zlib_strategy          (hHandle)
# YES?   mng_get_zlib_maxidat           (hHandle)
# YES?   mng_get_jpeg_dctmethod         (hHandle)
# YES?   mng_get_jpeg_quality           (hHandle)
# YES?   mng_get_jpeg_smoothing         (hHandle)
# YES?   mng_get_jpeg_progressive       (hHandle)
# YES?   mng_get_jpeg_optimized         (hHandle)
# YES?   mng_get_jpeg_maxjdat           (hHandle)
# YES?   mng_get_suspensionmode         (hHandle)
# YES?   mng_get_speed                  (hHandle)
# YES?   mng_get_imagelevel             (hHandle)
# YES?   mng_get_starttime              (hHandle)
# YES?   mng_get_runtime                (hHandle)
# YES?   mng_get_currentframe           (hHandle)
# YES?   mng_get_currentlayer           (hHandle)
# YES?   mng_get_currentplaytime        (hHandle)
# YES?   mng_status_error               (hHandle)
# YES?   mng_status_reading             (hHandle)
# YES?   mng_status_suspendbreak        (hHandle)
# YES?   mng_status_creating            (hHandle)
# YES?   mng_status_writing             (hHandle)
# YES?   mng_status_displaying          (hHandle)
# YES?   mng_status_running             (hHandle)
# YES?   mng_status_timerbreak          (hHandle)
# YES?   mng_iterate_chunks             (hHandle, iChunkseq, fProc)
#
# YES?   <list> mng_getchunk_ihdr       (hHandle, hChunk)
# YES?   <list> mng_getchunk_plte       (hHandle, hChunk)
# YES?   <list> mng_getchunk_idat       (hHandle, hChunk)
# YES?   <list> mng_getchunk_trns       (hHandle, hChunk)
# YES?   <list> mng_getchunk_gama       (hHandle, hChunk)
# YES?   <list> mng_getchunk_chrm       (hHandle, hChunk)
# YES?   <list> mng_getchunk_srgb       (hHandle, hChunk)
# YES?   <list> mng_getchunk_iccp       (hHandle, hChunk)
# YES?   <list> mng_getchunk_text       (hHandle, hChunk)
# YES?   <list> mng_getchunk_ztxt       (hHandle, hChunk)
# YES?   <list> mng_getchunk_itxt       (hHandle, hChunk)
# YES?   <list> mng_getchunk_bkgd       (hHandle, hChunk)
# YES?   <list> mng_getchunk_phys       (hHandle, hChunk)
# YES?   <list> mng_getchunk_sbit       (hHandle, hChunk)
# YES?   <list> mng_getchunk_splt       (hHandle, hChunk)
# YES?   <list> mng_getchunk_hist       (hHandle, hChunk)
# YES?   <list> mng_getchunk_time       (hHandle, hChunk)
# YES?   <list> mng_getchunk_mhdr       (hHandle, hChunk)
# YES?   <list> mng_getchunk_loop       (hHandle, hChunk)
# YES?   <list> mng_getchunk_endl       (hHandle, hChunk)
# YES?   <list> mng_getchunk_defi       (hHandle, hChunk)
# YES?   <list> mng_getchunk_basi       (hHandle, hChunk)
# YES?   <list> mng_getchunk_clon       (hHandle, hChunk)
# YES?   <list> mng_getchunk_past       (hHandle, hChunk)
# YES?   <list> mng_getchunk_past_src   (hHandle, hChunk)
# YES?   <list> mng_getchunk_disc       (hHandle, hChunk)
# YES?   <list> mng_getchunk_back       (hHandle, hChunk)
# YES?   <list> mng_getchunk_fram       (hHandle, hChunk)
# YES?   <list> mng_getchunk_move       (hHandle, hChunk)
# YES?   <list> mng_getchunk_clip       (hHandle, hChunk)
# YES?   <list> mng_getchunk_show       (hHandle, hChunk)
# YES?   <list> mng_getchunk_term       (hHandle, hChunk)
# YES?   <list> mng_getchunk_save       (hHandle, hChunk)
# YES?   <list> mng_getchunk_save_entry (hHandle, hChunk)
# YES?   <list> mng_getchunk_seek       (hHandle, hChunk)
# YES?   <list> mng_getchunk_expi       (hHandle, hChunk)
# YES?   <list> mng_getchunk_fpri       (hHandle, hChunk)
# YES?   <list> mng_getchunk_need       (hHandle, hChunk)
# YES?   <list> mng_getchunk_phyg       (hHandle, hChunk)
# YES?   <list> mng_getchunk_jhdr       (hHandle, hChunk)
# YES?   <list> mng_getchunk_jdat       (hHandle, hChunk)
# YES?   <list> mng_getchunk_jdaa       (hHandle, hChunk)
# YES?   <list> mng_getchunk_dhdr       (hHandle, hChunk)
# YES?   <list> mng_getchunk_prom       (hHandle, hChunk)
# YES?   <list> mng_getchunk_pplt       (hHandle, hChunk)
# YES?   <list> mng_getchunk_pplt_entry (hHandle, hChunk)
# YES?   <list> mng_getchunk_drop       (hHandle, hChunk)
# YES?   <list> mng_getchunk_dbyk       (hHandle, hChunk)
# YES?   <list> mng_getchunk_ordr       (hHandle, hChunk)
# YES?   <list> mng_getchunk_ordr_entry (hHandle, hChunk)
# YES?   <list> mng_getchunk_magn       (hHandle, hChunk)
# YES?   <list> mng_getchunk_unknown    (hHandle, hChunk)
# YES?   mng_putchunk_ihdr              (hHandle, iWidth, iHeight, iBitdepth, iColortype, iCompression, iFilter, iInterlace)
# YES?   mng_putchunk_plte              (hHandle, iCount, aPalette)
# YES?   mng_putchunk_idat              (hHandle, iRawlen, pRawdata)
# YES?   mng_putchunk_iend              (hHandle)
# YES?   mng_putchunk_trns              (hHandle, bEmpty, bGlobal, iType, iCount, aAlphas, iGray, iRed, iGreen, iBlue, iRawlen, aRawdata)
# YES?   mng_putchunk_gama              (hHandle, bEmpty, iGamma)
# YES?   mng_putchunk_chrm              (hHandle, bEmpty, iWhitepointx, iWhitepointy, iRedx, iRedy, iGreenx, iGreeny, iBluex, iBluey)
# YES?   mng_putchunk_srgb              (hHandle, bEmpty, iRenderingintent)
# YES?   mng_putchunk_iccp              (hHandle, bEmpty, iNamesize, zName, iCompression, iProfilesize, pProfile)
# YES?   mng_putchunk_text              (hHandle, iKeywordsize, zKeyword, iTextsize, zText)
# YES?   mng_putchunk_ztxt              (hHandle, iKeywordsize, zKeyword, iCompression, iTextsize, zText)
# YES?   mng_putchunk_itxt              (hHandle, iKeywordsize, zKeyword, iCompressionflag, iCompressionmethod, iLanguagesize, zLanguage, iTranslationsize, zTranslation, iTextsize, zText)
# YES?   mng_putchunk_bkgd              (hHandle, bEmpty, iType, iIndex, iGray, iRed, iGreen, iBlue)
# YES?   mng_putchunk_phys              (hHandle, bEmpty, iSizex, iSizey, iUnit)
# YES?   mng_putchunk_sbit              (hHandle, bEmpty, iType, aBits)
# YES?   mng_putchunk_splt              (hHandle, bEmpty, iNamesize, zName, iSampledepth, iEntrycount, pEntries)
# YES?   mng_putchunk_hist              (hHandle, iEntrycount, aEntries)
# YES?   mng_putchunk_time              (hHandle, iYear, iMonth, iDay, iHour, iMinute, iSecond)
# YES?   mng_putchunk_mhdr              (hHandle, iWidth, iHeight, iTicks, iLayercount, iFramecount, iPlaytime, iSimplicity)
# YES?   mng_putchunk_mend              (hHandle)
# YES?   mng_putchunk_loop              (hHandle, iLevel, iRepeat, iTermination, iItermin, iItermax, iCount, pSignals)
# YES?   mng_putchunk_endl              (hHandle, iLevel)
# YES?   mng_putchunk_defi              (hHandle, iObjectid, iDonotshow, iConcrete, bHasloca, iXlocation, iYlocation, bHasclip, iLeftcb, iRightcb, iTopcb, iBottomcb)
# YES?   mng_putchunk_basi              (hHandle, iWidth, iHeight, iBitdepth, iColortype, iCompression, iFilter, iInterlace, iRed, iGreen, iBlue, iAlpha, iViewable)
# YES?   mng_putchunk_clon              (hHandle, iSourceid, iCloneid, iClonetype, iDonotshow, iConcrete, bHasloca, iLocationtype, iLocationx, iLocationy)
# YES?   mng_putchunk_past              (hHandle, iDestid, iTargettype, iTargetx, iTargety, iCount)
# YES?   mng_putchunk_past_src          (hHandle, iEntry, iSourceid, iComposition, iOrientation, iOffsettype, iOffsetx, iOffsety, iBoundarytype, iBoundaryl, iBoundaryr, iBoundaryt, iBoundaryb)
# YES?   mng_putchunk_disc              (hHandle, iCount, pObjectids)
# YES?   mng_putchunk_back              (hHandle, iRed, iGreen, iBlue, iMandatory, iImageid, iTile)
# YES?   mng_putchunk_fram              (hHandle, bEmpty, iMode, iNamesize, zName, iChangedelay, iChangetimeout, iChangeclipping, iChangesyncid, iDelay, iTimeout, iBoundarytype, iBoundaryl, iBoundaryr, iBoundaryt, iBoundaryb, iCount, pSyncids)
# YES?   mng_putchunk_move              (hHandle, iFirstid, iLastid, iMovetype, iMovex, iMovey)
# YES?   mng_putchunk_clip              (hHandle, iFirstid, iLastid, iCliptype, iClipl, iClipr, iClipt, iClipb)
# YES?   mng_putchunk_show              (hHandle, bEmpty, iFirstid, iLastid, iMode)
# YES?   mng_putchunk_term              (hHandle, iTermaction, iIteraction, iDelay, iItermax)
# YES?   mng_putchunk_save              (hHandle, bEmpty, iOffsettype, iCount)
# YES?   mng_putchunk_save_entry        (hHandle, iEntry, iEntrytype, iOffset, iStarttime, iLayernr, iFramenr, iNamesize, zName)
# YES?   mng_putchunk_seek              (hHandle, iNamesize, zName)
# YES?   mng_putchunk_expi              (hHandle, iSnapshotid, iNamesize, zName)
# YES?   mng_putchunk_fpri              (hHandle, iDeltatype, iPriority)
# YES?   mng_putchunk_need              (hHandle, iKeywordssize, zKeywords)
# YES?   mng_putchunk_phyg              (hHandle, bEmpty, iSizex, iSizey, iUnit)
# YES?   mng_putchunk_jhdr              (hHandle, iWidth, iHeight, iColortype, iImagesampledepth, iImagecompression, iImageinterlace, iAlphasampledepth, iAlphacompression, iAlphafilter, iAlphainterlace)
# YES?   mng_putchunk_jdat              (hHandle, iRawlen, pRawdata)
# YES?   mng_putchunk_jdaa              (hHandle, iRawlen, pRawdata)
# YES?   mng_putchunk_jsep              (hHandle)
# YES?   mng_putchunk_dhdr              (hHandle, iObjectid, iImagetype, iDeltatype, iBlockwidth, iBlockheight, iBlockx, iBlocky)
# YES?   mng_putchunk_prom              (hHandle, iColortype, iSampledepth, iFilltype)
# YES?   mng_putchunk_ipng              (hHandle)
# YES?   mng_putchunk_pplt              (hHandle, iCount)
# YES?   mng_putchunk_pplt_entry        (hHandle, iEntry, iRed, iGreen, iBlue, iAlpha, bUsed)
# YES?   mng_putchunk_jpng              (hHandle)
# YES?   mng_putchunk_drop              (hHandle, iCount, pChunknames)
# YES?   mng_putchunk_dbyk              (hHandle, iChunkname, iPolarity, iKeywordssize, zKeywords)
# YES?   mng_putchunk_ordr              (hHandle, iCount)
# YES?   mng_putchunk_ordr_entry        (hHandle, iEntry, iChunkname, iOrdertype)
# YES?   mng_putchunk_magn              (hHandle, iFirstid, iLastid, iMethodX, iMX, iMY, iML, iMR, iMT, iMB, iMethodY)
# YES?   mng_putchunk_unknown           (hHandle, iChunkname, iRawlen, pRawdata)
# YES?   mng_getimgdata_seq             (hHandle, iSeqnr, iCanvasstyle, fGetcanvasline)
# YES?   mng_getimgdata_chunkseq        (hHandle, iSeqnr, iCanvasstyle, fGetcanvasline)
# YES?   mng_getimgdata_chunk           (hHandle, hChunk, iCanvasstyle, fGetcanvasline)
# YES?   mng_putimgdata_ihdr            (hHandle, iWidth, iHeight, iColortype, iBitdepth, iCompression, iFilter, iInterlace, iCanvasstyle, fGetcanvasline)
# YES?   mng_putimgdata_jhdr            (hHandle, iWidth, iHeight, iColortype, iBitdepth, iCompression, iInterlace, iAlphaBitdepth, iAlphaCompression, iAlphaFilter, iAlphaInterlace, iCanvasstyle, fGetcanvasline)
# YES?   mng_updatemngheader            (hHandle, iFramecount, iLayercount, iPlaytime)
# YES?   mng_updatemngsimplicity        (hHandle, iSimplicity)
#
#

void
mng_dummy()
   PROTOTYPE: 
   CODE:
   /*
   ===============================================================================
      These are the original prototypes for the functions that I still need to
      implement and/or test.  They are just here for quick reference.
   ===============================================================================
   MNG_EXT mng_retcode MNG_DECL mng_set_userdata        (mng_handle        hHandle,
                                                         mng_ptr           pUserdata);
   MNG_EXT mng_retcode MNG_DECL mng_set_canvasstyle     (mng_handle        hHandle,
                                                         mng_uint32        iStyle);
   MNG_EXT mng_retcode MNG_DECL mng_set_bkgdstyle       (mng_handle        hHandle,
                                                         mng_uint32        iStyle);
   MNG_EXT mng_retcode MNG_DECL mng_set_bgcolor         (mng_handle        hHandle,
                                                         mng_uint16        iRed,
                                                         mng_uint16        iGreen,
                                                         mng_uint16        iBlue);
   MNG_EXT mng_retcode MNG_DECL mng_set_usebkgd         (mng_handle        hHandle,
                                                         mng_bool          bUseBKGD);
   MNG_EXT mng_retcode MNG_DECL mng_set_storechunks     (mng_handle        hHandle,
                                                         mng_bool          bStorechunks);
   MNG_EXT mng_retcode MNG_DECL mng_set_sectionbreaks   (mng_handle        hHandle,
                                                         mng_bool          bSectionbreaks);
   MNG_EXT mng_retcode MNG_DECL mng_set_cacheplayback   (mng_handle        hHandle,
                                                         mng_bool          bCacheplayback);
   MNG_EXT mng_retcode MNG_DECL mng_set_doprogressive   (mng_handle        hHandle,
                                                         mng_bool          bDoProgressive);
   MNG_EXT mng_retcode MNG_DECL mng_set_srgb            (mng_handle        hHandle,
                                                         mng_bool          bIssRGB);
   MNG_EXT mng_retcode MNG_DECL mng_set_outputprofile   (mng_handle        hHandle,
                                                         mng_pchar         zFilename);
   MNG_EXT mng_retcode MNG_DECL mng_set_outputprofile2  (mng_handle        hHandle,
                                                         mng_uint32        iProfilesize,
                                                         mng_ptr           pProfile);
   MNG_EXT mng_retcode MNG_DECL mng_set_outputsrgb      (mng_handle        hHandle);
   MNG_EXT mng_retcode MNG_DECL mng_set_srgbprofile     (mng_handle        hHandle,
                                                         mng_pchar         zFilename);
   MNG_EXT mng_retcode MNG_DECL mng_set_srgbprofile2    (mng_handle        hHandle,
                                                         mng_uint32        iProfilesize,
                                                         mng_ptr           pProfile);
   MNG_EXT mng_retcode MNG_DECL mng_set_srgbimplicit    (mng_handle        hHandle);
   MNG_EXT mng_retcode MNG_DECL mng_set_viewgamma       (mng_handle        hHandle,
                                                         mng_float         dGamma);
   MNG_EXT mng_retcode MNG_DECL mng_set_displaygamma    (mng_handle        hHandle,
                                                         mng_float         dGamma);
   MNG_EXT mng_retcode MNG_DECL mng_set_dfltimggamma    (mng_handle        hHandle,
                                                         mng_float         dGamma);
   MNG_EXT mng_retcode MNG_DECL mng_set_viewgammaint    (mng_handle        hHandle,
                                                         mng_uint32        iGamma);
   MNG_EXT mng_retcode MNG_DECL mng_set_displaygammaint (mng_handle        hHandle,
                                                         mng_uint32        iGamma);
   MNG_EXT mng_retcode MNG_DECL mng_set_dfltimggammaint (mng_handle        hHandle,
                                                         mng_uint32        iGamma);
   MNG_EXT mng_retcode MNG_DECL mng_set_maxcanvaswidth  (mng_handle        hHandle,
                                                         mng_uint32        iMaxwidth);
   MNG_EXT mng_retcode MNG_DECL mng_set_maxcanvasheight (mng_handle        hHandle,
                                                         mng_uint32        iMaxheight);
   MNG_EXT mng_retcode MNG_DECL mng_set_maxcanvassize   (mng_handle        hHandle,
                                                         mng_uint32        iMaxwidth,
                                                         mng_uint32        iMaxheight);
   MNG_EXT mng_retcode MNG_DECL mng_set_zlib_level      (mng_handle        hHandle,
                                                         mng_int32         iZlevel);
   MNG_EXT mng_retcode MNG_DECL mng_set_zlib_method     (mng_handle        hHandle,
                                                         mng_int32         iZmethod);
   MNG_EXT mng_retcode MNG_DECL mng_set_zlib_windowbits (mng_handle        hHandle,
                                                         mng_int32         iZwindowbits);
   MNG_EXT mng_retcode MNG_DECL mng_set_zlib_memlevel   (mng_handle        hHandle,
                                                         mng_int32         iZmemlevel);
   MNG_EXT mng_retcode MNG_DECL mng_set_zlib_strategy   (mng_handle        hHandle,
                                                         mng_int32         iZstrategy);
   MNG_EXT mng_retcode MNG_DECL mng_set_zlib_maxidat    (mng_handle        hHandle,
                                                         mng_uint32        iMaxIDAT);
   MNG_EXT mng_retcode MNG_DECL mng_set_jpeg_dctmethod  (mng_handle        hHandle,
                                                         mngjpeg_dctmethod eJPEGdctmethod);
   MNG_EXT mng_retcode MNG_DECL mng_set_jpeg_quality    (mng_handle        hHandle,
                                                         mng_int32         iJPEGquality);
   MNG_EXT mng_retcode MNG_DECL mng_set_jpeg_smoothing  (mng_handle        hHandle,
                                                         mng_int32         iJPEGsmoothing);
   MNG_EXT mng_retcode MNG_DECL mng_set_jpeg_progressive(mng_handle        hHandle,
                                                         mng_bool          bJPEGprogressive);
   MNG_EXT mng_retcode MNG_DECL mng_set_jpeg_optimized  (mng_handle        hHandle,
                                                         mng_bool          bJPEGoptimized);
   MNG_EXT mng_retcode MNG_DECL mng_set_jpeg_maxjdat    (mng_handle        hHandle,
                                                         mng_uint32        iMaxJDAT);
   MNG_EXT mng_retcode MNG_DECL mng_set_suspensionmode  (mng_handle        hHandle,
                                                         mng_bool          bSuspensionmode);
   MNG_EXT mng_retcode MNG_DECL mng_set_speed           (mng_handle        hHandle,
                                                         mng_speedtype     iSpeed);
   MNG_EXT mng_ptr     MNG_DECL mng_get_userdata        (mng_handle        hHandle);
   MNG_EXT mng_imgtype MNG_DECL mng_get_sigtype         (mng_handle        hHandle);
   MNG_EXT mng_imgtype MNG_DECL mng_get_imagetype       (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_imagewidth      (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_imageheight     (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_ticks           (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_framecount      (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_layercount      (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_playtime        (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_simplicity      (mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_bitdepth        (mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_colortype       (mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_compression     (mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_filter          (mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_interlace       (mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_alphabitdepth   (mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_alphacompression(mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_alphafilter     (mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_alphainterlace  (mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_alphadepth      (mng_handle        hHandle);
   MNG_EXT mng_uint8   MNG_DECL mng_get_refreshpass     (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_canvasstyle     (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_bkgdstyle       (mng_handle        hHandle);
   MNG_EXT mng_retcode MNG_DECL mng_get_bgcolor         (mng_handle        hHandle,
                                                         mng_uint16*       iRed,
                                                         mng_uint16*       iGreen,
                                                         mng_uint16*       iBlue);
   MNG_EXT mng_bool    MNG_DECL mng_get_usebkgd         (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_get_storechunks     (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_get_sectionbreaks   (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_get_cacheplayback   (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_get_doprogressive   (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_get_srgb            (mng_handle        hHandle);
   MNG_EXT mng_float   MNG_DECL mng_get_viewgamma       (mng_handle        hHandle);
   MNG_EXT mng_float   MNG_DECL mng_get_displaygamma    (mng_handle        hHandle);
   MNG_EXT mng_float   MNG_DECL mng_get_dfltimggamma    (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_viewgammaint    (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_displaygammaint (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_dfltimggammaint (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_maxcanvaswidth  (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_maxcanvasheight (mng_handle        hHandle);
   MNG_EXT mng_int32   MNG_DECL mng_get_zlib_level      (mng_handle        hHandle);
   MNG_EXT mng_int32   MNG_DECL mng_get_zlib_method     (mng_handle        hHandle);
   MNG_EXT mng_int32   MNG_DECL mng_get_zlib_windowbits (mng_handle        hHandle);
   MNG_EXT mng_int32   MNG_DECL mng_get_zlib_memlevel   (mng_handle        hHandle);
   MNG_EXT mng_int32   MNG_DECL mng_get_zlib_strategy   (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_zlib_maxidat    (mng_handle        hHandle);
   MNG_EXT mngjpeg_dctmethod
                       MNG_DECL mng_get_jpeg_dctmethod  (mng_handle        hHandle);
   MNG_EXT mng_int32   MNG_DECL mng_get_jpeg_quality    (mng_handle        hHandle);
   MNG_EXT mng_int32   MNG_DECL mng_get_jpeg_smoothing  (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_get_jpeg_progressive(mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_get_jpeg_optimized  (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_jpeg_maxjdat    (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_get_suspensionmode  (mng_handle        hHandle);
   MNG_EXT mng_speedtype
                       MNG_DECL mng_get_speed           (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_imagelevel      (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_starttime       (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_runtime         (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_currentframe    (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_currentlayer    (mng_handle        hHandle);
   MNG_EXT mng_uint32  MNG_DECL mng_get_currentplaytime (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_status_error        (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_status_reading      (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_status_suspendbreak (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_status_creating     (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_status_writing      (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_status_displaying   (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_status_running      (mng_handle        hHandle);
   MNG_EXT mng_bool    MNG_DECL mng_status_timerbreak   (mng_handle        hHandle);
   MNG_EXT mng_retcode MNG_DECL mng_iterate_chunks      (mng_handle       hHandle,
                                                         mng_uint32       iChunkseq,
                                                         mng_iteratechunk fProc);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_ihdr       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iWidth,
                                                         mng_uint32       *iHeight,
                                                         mng_uint8        *iBitdepth,
                                                         mng_uint8        *iColortype,
                                                         mng_uint8        *iCompression,
                                                         mng_uint8        *iFilter,
                                                         mng_uint8        *iInterlace);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_plte       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iCount,
                                                         mng_palette8     *aPalette);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_idat       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iRawlen,
                                                         mng_ptr          *pRawdata);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_trns       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_bool         *bGlobal,
                                                         mng_uint8        *iType,
                                                         mng_uint32       *iCount,
                                                         mng_uint8arr     *aAlphas,
                                                         mng_uint16       *iGray,
                                                         mng_uint16       *iRed,
                                                         mng_uint16       *iGreen,
                                                         mng_uint16       *iBlue,
                                                         mng_uint32       *iRawlen,
                                                         mng_uint8arr     *aRawdata);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_gama       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint32       *iGamma);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_chrm       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint32       *iWhitepointx,
                                                         mng_uint32       *iWhitepointy,
                                                         mng_uint32       *iRedx,
                                                         mng_uint32       *iRedy,
                                                         mng_uint32       *iGreenx,
                                                         mng_uint32       *iGreeny,
                                                         mng_uint32       *iBluex,
                                                         mng_uint32       *iBluey);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_srgb       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint8        *iRenderingintent);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_iccp       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint32       *iNamesize,
                                                         mng_pchar        *zName,
                                                         mng_uint8        *iCompression,
                                                         mng_uint32       *iProfilesize,
                                                         mng_ptr          *pProfile);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_text       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iKeywordsize,
                                                         mng_pchar        *zKeyword,
                                                         mng_uint32       *iTextsize,
                                                         mng_pchar        *zText);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_ztxt       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iKeywordsize,
                                                         mng_pchar        *zKeyword,
                                                         mng_uint8        *iCompression,
                                                         mng_uint32       *iTextsize,
                                                         mng_pchar        *zText);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_itxt       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iKeywordsize,
                                                         mng_pchar        *zKeyword,
                                                         mng_uint8        *iCompressionflag,
                                                         mng_uint8        *iCompressionmethod,
                                                         mng_uint32       *iLanguagesize,
                                                         mng_pchar        *zLanguage,
                                                         mng_uint32       *iTranslationsize,
                                                         mng_pchar        *zTranslation,
                                                         mng_uint32       *iTextsize,
                                                         mng_pchar        *zText);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_bkgd       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint8        *iType,
                                                         mng_uint8        *iIndex,
                                                         mng_uint16       *iGray,
                                                         mng_uint16       *iRed,
                                                         mng_uint16       *iGreen,
                                                         mng_uint16       *iBlue);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_phys       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint32       *iSizex,
                                                         mng_uint32       *iSizey,
                                                         mng_uint8        *iUnit);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_sbit       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint8        *iType,
                                                         mng_uint8arr4    *aBits);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_splt       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint32       *iNamesize,
                                                         mng_pchar        *zName,
                                                         mng_uint8        *iSampledepth,
                                                         mng_uint32       *iEntrycount,
                                                         mng_ptr          *pEntries);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_hist       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iEntrycount,
                                                         mng_uint16arr    *aEntries);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_time       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint16       *iYear,
                                                         mng_uint8        *iMonth,
                                                         mng_uint8        *iDay,
                                                         mng_uint8        *iHour,
                                                         mng_uint8        *iMinute,
                                                         mng_uint8        *iSecond);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_mhdr       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iWidth,
                                                         mng_uint32       *iHeight,
                                                         mng_uint32       *iTicks,
                                                         mng_uint32       *iLayercount,
                                                         mng_uint32       *iFramecount,
                                                         mng_uint32       *iPlaytime,
                                                         mng_uint32       *iSimplicity);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_loop       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint8        *iLevel,
                                                         mng_uint32       *iRepeat,
                                                         mng_uint8        *iTermination,
                                                         mng_uint32       *iItermin,
                                                         mng_uint32       *iItermax,
                                                         mng_uint32       *iCount,
                                                         mng_uint32p      *pSignals);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_endl       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint8        *iLevel);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_defi       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint16       *iObjectid,
                                                         mng_uint8        *iDonotshow,
                                                         mng_uint8        *iConcrete,
                                                         mng_bool         *bHasloca,
                                                         mng_int32        *iXlocation,
                                                         mng_int32        *iYlocation,
                                                         mng_bool         *bHasclip,
                                                         mng_int32        *iLeftcb,
                                                         mng_int32        *iRightcb,
                                                         mng_int32        *iTopcb,
                                                         mng_int32        *iBottomcb);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_basi       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iWidth,
                                                         mng_uint32       *iHeight,
                                                         mng_uint8        *iBitdepth,
                                                         mng_uint8        *iColortype,
                                                         mng_uint8        *iCompression,
                                                         mng_uint8        *iFilter,
                                                         mng_uint8        *iInterlace,
                                                         mng_uint16       *iRed,
                                                         mng_uint16       *iGreen,
                                                         mng_uint16       *iBlue,
                                                         mng_uint16       *iAlpha,
                                                         mng_uint8        *iViewable);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_clon       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint16       *iSourceid,
                                                         mng_uint16       *iCloneid,
                                                         mng_uint8        *iClonetype,
                                                         mng_uint8        *iDonotshow,
                                                         mng_uint8        *iConcrete,
                                                         mng_bool         *bHasloca,
                                                         mng_uint8        *iLocationtype,
                                                         mng_int32        *iLocationx,
                                                         mng_int32        *iLocationy);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_past       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint16       *iDestid,
                                                         mng_uint8        *iTargettype,
                                                         mng_int32        *iTargetx,
                                                         mng_int32        *iTargety,
                                                         mng_uint32       *iCount);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_past_src   (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       iEntry,
                                                         mng_uint16       *iSourceid,
                                                         mng_uint8        *iComposition,
                                                         mng_uint8        *iOrientation,
                                                         mng_uint8        *iOffsettype,
                                                         mng_int32        *iOffsetx,
                                                         mng_int32        *iOffsety,
                                                         mng_uint8        *iBoundarytype,
                                                         mng_int32        *iBoundaryl,
                                                         mng_int32        *iBoundaryr,
                                                         mng_int32        *iBoundaryt,
                                                         mng_int32        *iBoundaryb);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_disc       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iCount,
                                                         mng_uint16p      *pObjectids);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_back       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint16       *iRed,
                                                         mng_uint16       *iGreen,
                                                         mng_uint16       *iBlue,
                                                         mng_uint8        *iMandatory,
                                                         mng_uint16       *iImageid,
                                                         mng_uint8        *iTile);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_fram       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint8        *iMode,
                                                         mng_uint32       *iNamesize,
                                                         mng_pchar        *zName,
                                                         mng_uint8        *iChangedelay,
                                                         mng_uint8        *iChangetimeout,
                                                         mng_uint8        *iChangeclipping,
                                                         mng_uint8        *iChangesyncid,
                                                         mng_uint32       *iDelay,
                                                         mng_uint32       *iTimeout,
                                                         mng_uint8        *iBoundarytype,
                                                         mng_int32        *iBoundaryl,
                                                         mng_int32        *iBoundaryr,
                                                         mng_int32        *iBoundaryt,
                                                         mng_int32        *iBoundaryb,
                                                         mng_uint32       *iCount,
                                                         mng_uint32p      *pSyncids);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_move       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint16       *iFirstid,
                                                         mng_uint16       *iLastid,
                                                         mng_uint8        *iMovetype,
                                                         mng_int32        *iMovex,
                                                         mng_int32        *iMovey);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_clip       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint16       *iFirstid,
                                                         mng_uint16       *iLastid,
                                                         mng_uint8        *iCliptype,
                                                         mng_int32        *iClipl,
                                                         mng_int32        *iClipr,
                                                         mng_int32        *iClipt,
                                                         mng_int32        *iClipb);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_show       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint16       *iFirstid,
                                                         mng_uint16       *iLastid,
                                                         mng_uint8        *iMode);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_term       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint8        *iTermaction,
                                                         mng_uint8        *iIteraction,
                                                         mng_uint32       *iDelay,
                                                         mng_uint32       *iItermax);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_save       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint8        *iOffsettype,
                                                         mng_uint32       *iCount);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_save_entry (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       iEntry,
                                                         mng_uint8        *iEntrytype,
                                                         mng_uint32arr2   *iOffset,
                                                         mng_uint32arr2   *iStarttime,
                                                         mng_uint32       *iLayernr,
                                                         mng_uint32       *iFramenr,
                                                         mng_uint32       *iNamesize,
                                                         mng_pchar        *zName);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_seek       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iNamesize,
                                                         mng_pchar        *zName);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_expi       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint16       *iSnapshotid,
                                                         mng_uint32       *iNamesize,
                                                         mng_pchar        *zName);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_fpri       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint8        *iDeltatype,
                                                         mng_uint8        *iPriority);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_need       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iKeywordssize,
                                                         mng_pchar        *zKeywords);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_phyg       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_bool         *bEmpty,
                                                         mng_uint32       *iSizex,
                                                         mng_uint32       *iSizey,
                                                         mng_uint8        *iUnit);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_jhdr       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iWidth,
                                                         mng_uint32       *iHeight,
                                                         mng_uint8        *iColortype,
                                                         mng_uint8        *iImagesampledepth,
                                                         mng_uint8        *iImagecompression,
                                                         mng_uint8        *iImageinterlace,
                                                         mng_uint8        *iAlphasampledepth,
                                                         mng_uint8        *iAlphacompression,
                                                         mng_uint8        *iAlphafilter,
                                                         mng_uint8        *iAlphainterlace);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_jdat       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iRawlen,
                                                         mng_ptr          *pRawdata);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_jdaa       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iRawlen,
                                                         mng_ptr          *pRawdata);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_dhdr       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint16       *iObjectid,
                                                         mng_uint8        *iImagetype,
                                                         mng_uint8        *iDeltatype,
                                                         mng_uint32       *iBlockwidth,
                                                         mng_uint32       *iBlockheight,
                                                         mng_uint32       *iBlockx,
                                                         mng_uint32       *iBlocky);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_prom       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint8        *iColortype,
                                                         mng_uint8        *iSampledepth,
                                                         mng_uint8        *iFilltype);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_pplt       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iCount);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_pplt_entry (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       iEntry,
                                                         mng_uint16       *iRed,
                                                         mng_uint16       *iGreen,
                                                         mng_uint16       *iBlue,
                                                         mng_uint16       *iAlpha,
                                                         mng_bool         *bUsed);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_drop       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iCount,
                                                         mng_chunkidp     *pChunknames);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_dbyk       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_chunkid      *iChunkname,
                                                         mng_uint8        *iPolarity,
                                                         mng_uint32       *iKeywordssize,
                                                         mng_pchar        *zKeywords);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_ordr       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       *iCount);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_ordr_entry (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint32       iEntry,
                                                         mng_chunkid      *iChunkname,
                                                         mng_uint8        *iOrdertype);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_magn       (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_uint16       *iFirstid,
                                                         mng_uint16       *iLastid,
                                                         mng_uint16       *iMethodX,
                                                         mng_uint16       *iMX,
                                                         mng_uint16       *iMY,
                                                         mng_uint16       *iML,
                                                         mng_uint16       *iMR,
                                                         mng_uint16       *iMT,
                                                         mng_uint16       *iMB,
                                                         mng_uint16       *iMethodY);
   MNG_EXT mng_retcode MNG_DECL mng_getchunk_unknown    (mng_handle       hHandle,
                                                         mng_handle       hChunk,
                                                         mng_chunkid      *iChunkname,
                                                         mng_uint32       *iRawlen,
                                                         mng_ptr          *pRawdata);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_ihdr       (mng_handle       hHandle,
                                                         mng_uint32       iWidth,
                                                         mng_uint32       iHeight,
                                                         mng_uint8        iBitdepth,
                                                         mng_uint8        iColortype,
                                                         mng_uint8        iCompression,
                                                         mng_uint8        iFilter,
                                                         mng_uint8        iInterlace);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_plte       (mng_handle       hHandle,
                                                         mng_uint32       iCount,
                                                         mng_palette8     aPalette);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_idat       (mng_handle       hHandle,
                                                         mng_uint32       iRawlen,
                                                         mng_ptr          pRawdata);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_iend       (mng_handle       hHandle);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_trns       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_bool         bGlobal,
                                                         mng_uint8        iType,
                                                         mng_uint32       iCount,
                                                         mng_uint8arr     aAlphas,
                                                         mng_uint16       iGray,
                                                         mng_uint16       iRed,
                                                         mng_uint16       iGreen,
                                                         mng_uint16       iBlue,
                                                         mng_uint32       iRawlen,
                                                         mng_uint8arr     aRawdata);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_gama       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint32       iGamma);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_chrm       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint32       iWhitepointx,
                                                         mng_uint32       iWhitepointy,
                                                         mng_uint32       iRedx,
                                                         mng_uint32       iRedy,
                                                         mng_uint32       iGreenx,
                                                         mng_uint32       iGreeny,
                                                         mng_uint32       iBluex,
                                                         mng_uint32       iBluey);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_srgb       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint8        iRenderingintent);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_iccp       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint32       iNamesize,
                                                         mng_pchar        zName,
                                                         mng_uint8        iCompression,
                                                         mng_uint32       iProfilesize,
                                                         mng_ptr          pProfile);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_text       (mng_handle       hHandle,
                                                         mng_uint32       iKeywordsize,
                                                         mng_pchar        zKeyword,
                                                         mng_uint32       iTextsize,
                                                         mng_pchar        zText);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_ztxt       (mng_handle       hHandle,
                                                         mng_uint32       iKeywordsize,
                                                         mng_pchar        zKeyword,
                                                         mng_uint8        iCompression,
                                                         mng_uint32       iTextsize,
                                                         mng_pchar        zText);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_itxt       (mng_handle       hHandle,
                                                         mng_uint32       iKeywordsize,
                                                         mng_pchar        zKeyword,
                                                         mng_uint8        iCompressionflag,
                                                         mng_uint8        iCompressionmethod,
                                                         mng_uint32       iLanguagesize,
                                                         mng_pchar        zLanguage,
                                                         mng_uint32       iTranslationsize,
                                                         mng_pchar        zTranslation,
                                                         mng_uint32       iTextsize,
                                                         mng_pchar        zText);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_bkgd       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint8        iType,
                                                         mng_uint8        iIndex,
                                                         mng_uint16       iGray,
                                                         mng_uint16       iRed,
                                                         mng_uint16       iGreen,
                                                         mng_uint16       iBlue);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_phys       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint32       iSizex,
                                                         mng_uint32       iSizey,
                                                         mng_uint8        iUnit);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_sbit       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint8        iType,
                                                         mng_uint8arr4    aBits);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_splt       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint32       iNamesize,
                                                         mng_pchar        zName,
                                                         mng_uint8        iSampledepth,
                                                         mng_uint32       iEntrycount,
                                                         mng_ptr          pEntries);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_hist       (mng_handle       hHandle,
                                                         mng_uint32       iEntrycount,
                                                         mng_uint16arr    aEntries);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_time       (mng_handle       hHandle,
                                                         mng_uint16       iYear,
                                                         mng_uint8        iMonth,
                                                         mng_uint8        iDay,
                                                         mng_uint8        iHour,
                                                         mng_uint8        iMinute,
                                                         mng_uint8        iSecond);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_mhdr       (mng_handle       hHandle,
                                                         mng_uint32       iWidth,
                                                         mng_uint32       iHeight,
                                                         mng_uint32       iTicks,
                                                         mng_uint32       iLayercount,
                                                         mng_uint32       iFramecount,
                                                         mng_uint32       iPlaytime,
                                                         mng_uint32       iSimplicity);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_mend       (mng_handle       hHandle);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_loop       (mng_handle       hHandle,
                                                         mng_uint8        iLevel,
                                                         mng_uint32       iRepeat,
                                                         mng_uint8        iTermination,
                                                         mng_uint32       iItermin,
                                                         mng_uint32       iItermax,
                                                         mng_uint32       iCount,
                                                         mng_uint32p      pSignals);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_endl       (mng_handle       hHandle,
                                                         mng_uint8        iLevel);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_defi       (mng_handle       hHandle,
                                                         mng_uint16       iObjectid,
                                                         mng_uint8        iDonotshow,
                                                         mng_uint8        iConcrete,
                                                         mng_bool         bHasloca,
                                                         mng_int32        iXlocation,
                                                         mng_int32        iYlocation,
                                                         mng_bool         bHasclip,
                                                         mng_int32        iLeftcb,
                                                         mng_int32        iRightcb,
                                                         mng_int32        iTopcb,
                                                         mng_int32        iBottomcb);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_basi       (mng_handle       hHandle,
                                                         mng_uint32       iWidth,
                                                         mng_uint32       iHeight,
                                                         mng_uint8        iBitdepth,
                                                         mng_uint8        iColortype,
                                                         mng_uint8        iCompression,
                                                         mng_uint8        iFilter,
                                                         mng_uint8        iInterlace,
                                                         mng_uint16       iRed,
                                                         mng_uint16       iGreen,
                                                         mng_uint16       iBlue,
                                                         mng_uint16       iAlpha,
                                                         mng_uint8        iViewable);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_clon       (mng_handle       hHandle,
                                                         mng_uint16       iSourceid,
                                                         mng_uint16       iCloneid,
                                                         mng_uint8        iClonetype,
                                                         mng_uint8        iDonotshow,
                                                         mng_uint8        iConcrete,
                                                         mng_bool         bHasloca,
                                                         mng_uint8        iLocationtype,
                                                         mng_int32        iLocationx,
                                                         mng_int32        iLocationy);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_past       (mng_handle       hHandle,
                                                         mng_uint16       iDestid,
                                                         mng_uint8        iTargettype,
                                                         mng_int32        iTargetx,
                                                         mng_int32        iTargety,
                                                         mng_uint32       iCount);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_past_src   (mng_handle       hHandle,
                                                         mng_uint32       iEntry,
                                                         mng_uint16       iSourceid,
                                                         mng_uint8        iComposition,
                                                         mng_uint8        iOrientation,
                                                         mng_uint8        iOffsettype,
                                                         mng_int32        iOffsetx,
                                                         mng_int32        iOffsety,
                                                         mng_uint8        iBoundarytype,
                                                         mng_int32        iBoundaryl,
                                                         mng_int32        iBoundaryr,
                                                         mng_int32        iBoundaryt,
                                                         mng_int32        iBoundaryb);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_disc       (mng_handle       hHandle,
                                                         mng_uint32       iCount,
                                                         mng_uint16p      pObjectids);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_back       (mng_handle       hHandle,
                                                         mng_uint16       iRed,
                                                         mng_uint16       iGreen,
                                                         mng_uint16       iBlue,
                                                         mng_uint8        iMandatory,
                                                         mng_uint16       iImageid,
                                                         mng_uint8        iTile);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_fram       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint8        iMode,
                                                         mng_uint32       iNamesize,
                                                         mng_pchar        zName,
                                                         mng_uint8        iChangedelay,
                                                         mng_uint8        iChangetimeout,
                                                         mng_uint8        iChangeclipping,
                                                         mng_uint8        iChangesyncid,
                                                         mng_uint32       iDelay,
                                                         mng_uint32       iTimeout,
                                                         mng_uint8        iBoundarytype,
                                                         mng_int32        iBoundaryl,
                                                         mng_int32        iBoundaryr,
                                                         mng_int32        iBoundaryt,
                                                         mng_int32        iBoundaryb,
                                                         mng_uint32       iCount,
                                                         mng_uint32p      pSyncids);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_move       (mng_handle       hHandle,
                                                         mng_uint16       iFirstid,
                                                         mng_uint16       iLastid,
                                                         mng_uint8        iMovetype,
                                                         mng_int32        iMovex,
                                                         mng_int32        iMovey);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_clip       (mng_handle       hHandle,
                                                         mng_uint16       iFirstid,
                                                         mng_uint16       iLastid,
                                                         mng_uint8        iCliptype,
                                                         mng_int32        iClipl,
                                                         mng_int32        iClipr,
                                                         mng_int32        iClipt,
                                                         mng_int32        iClipb);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_show       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint16       iFirstid,
                                                         mng_uint16       iLastid,
                                                         mng_uint8        iMode);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_term       (mng_handle       hHandle,
                                                         mng_uint8        iTermaction,
                                                         mng_uint8        iIteraction,
                                                         mng_uint32       iDelay,
                                                         mng_uint32       iItermax);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_save       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint8        iOffsettype,
                                                         mng_uint32       iCount);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_save_entry (mng_handle       hHandle,
                                                         mng_uint32       iEntry,
                                                         mng_uint8        iEntrytype,
                                                         mng_uint32arr2   iOffset,
                                                         mng_uint32arr2   iStarttime,
                                                         mng_uint32       iLayernr,
                                                         mng_uint32       iFramenr,
                                                         mng_uint32       iNamesize,
                                                         mng_pchar        zName);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_seek       (mng_handle       hHandle,
                                                         mng_uint32       iNamesize,
                                                         mng_pchar        zName);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_expi       (mng_handle       hHandle,
                                                         mng_uint16       iSnapshotid,
                                                         mng_uint32       iNamesize,
                                                         mng_pchar        zName);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_fpri       (mng_handle       hHandle,
                                                         mng_uint8        iDeltatype,
                                                         mng_uint8        iPriority);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_need       (mng_handle       hHandle,
                                                         mng_uint32       iKeywordssize,
                                                         mng_pchar        zKeywords);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_phyg       (mng_handle       hHandle,
                                                         mng_bool         bEmpty,
                                                         mng_uint32       iSizex,
                                                         mng_uint32       iSizey,
                                                         mng_uint8        iUnit);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_jhdr       (mng_handle       hHandle,
                                                         mng_uint32       iWidth,
                                                         mng_uint32       iHeight,
                                                         mng_uint8        iColortype,
                                                         mng_uint8        iImagesampledepth,
                                                         mng_uint8        iImagecompression,
                                                         mng_uint8        iImageinterlace,
                                                         mng_uint8        iAlphasampledepth,
                                                         mng_uint8        iAlphacompression,
                                                         mng_uint8        iAlphafilter,
                                                         mng_uint8        iAlphainterlace);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_jdat       (mng_handle       hHandle,
                                                         mng_uint32       iRawlen,
                                                         mng_ptr          pRawdata);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_jdaa       (mng_handle       hHandle,
                                                         mng_uint32       iRawlen,
                                                         mng_ptr          pRawdata);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_jsep       (mng_handle       hHandle);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_dhdr       (mng_handle       hHandle,
                                                         mng_uint16       iObjectid,
                                                         mng_uint8        iImagetype,
                                                         mng_uint8        iDeltatype,
                                                         mng_uint32       iBlockwidth,
                                                         mng_uint32       iBlockheight,
                                                         mng_uint32       iBlockx,
                                                         mng_uint32       iBlocky);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_prom       (mng_handle       hHandle,
                                                         mng_uint8        iColortype,
                                                         mng_uint8        iSampledepth,
                                                         mng_uint8        iFilltype);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_ipng       (mng_handle       hHandle);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_pplt       (mng_handle       hHandle,
                                                         mng_uint32       iCount);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_pplt_entry (mng_handle       hHandle,
                                                         mng_uint32       iEntry,
                                                         mng_uint16       iRed,
                                                         mng_uint16       iGreen,
                                                         mng_uint16       iBlue,
                                                         mng_uint16       iAlpha,
                                                         mng_bool         bUsed);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_jpng       (mng_handle       hHandle);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_drop       (mng_handle       hHandle,
                                                         mng_uint32       iCount,
                                                         mng_chunkidp     pChunknames);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_dbyk       (mng_handle       hHandle,
                                                         mng_chunkid      iChunkname,
                                                         mng_uint8        iPolarity,
                                                         mng_uint32       iKeywordssize,
                                                         mng_pchar        zKeywords);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_ordr       (mng_handle       hHandle,
                                                         mng_uint32       iCount);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_ordr_entry (mng_handle       hHandle,
                                                         mng_uint32       iEntry,
                                                         mng_chunkid      iChunkname,
                                                         mng_uint8        iOrdertype);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_magn       (mng_handle       hHandle,
                                                         mng_uint16       iFirstid,
                                                         mng_uint16       iLastid,
                                                         mng_uint16       iMethodX,
                                                         mng_uint16       iMX,
                                                         mng_uint16       iMY,
                                                         mng_uint16       iML,
                                                         mng_uint16       iMR,
                                                         mng_uint16       iMT,
                                                         mng_uint16       iMB,
                                                         mng_uint16       iMethodY);
   MNG_EXT mng_retcode MNG_DECL mng_putchunk_unknown    (mng_handle       hHandle,
                                                         mng_chunkid      iChunkname,
                                                         mng_uint32       iRawlen,
                                                         mng_ptr          pRawdata);


   MNG_EXT mng_retcode MNG_DECL mng_getimgdata_seq      (mng_handle        hHandle,
                                                         mng_uint32        iSeqnr,
                                                         mng_uint32        iCanvasstyle,
                                                         mng_getcanvasline fGetcanvasline);
   MNG_EXT mng_retcode MNG_DECL mng_getimgdata_chunkseq (mng_handle        hHandle,
                                                         mng_uint32        iSeqnr,
                                                         mng_uint32        iCanvasstyle,
                                                         mng_getcanvasline fGetcanvasline);
   MNG_EXT mng_retcode MNG_DECL mng_getimgdata_chunk    (mng_handle        hHandle,
                                                         mng_handle        hChunk,
                                                         mng_uint32        iCanvasstyle,
                                                         mng_getcanvasline fGetcanvasline);
   MNG_EXT mng_retcode MNG_DECL mng_putimgdata_ihdr     (mng_handle        hHandle,
                                                         mng_uint32        iWidth,
                                                         mng_uint32        iHeight,
                                                         mng_uint8         iColortype,
                                                         mng_uint8         iBitdepth,
                                                         mng_uint8         iCompression,
                                                         mng_uint8         iFilter,
                                                         mng_uint8         iInterlace,
                                                         mng_uint32        iCanvasstyle,
                                                         mng_getcanvasline fGetcanvasline);
   MNG_EXT mng_retcode MNG_DECL mng_putimgdata_jhdr     (mng_handle        hHandle,
                                                         mng_uint32        iWidth,
                                                         mng_uint32        iHeight,
                                                         mng_uint8         iColortype,
                                                         mng_uint8         iBitdepth,
                                                         mng_uint8         iCompression,
                                                         mng_uint8         iInterlace,
                                                         mng_uint8         iAlphaBitdepth,
                                                         mng_uint8         iAlphaCompression,
                                                         mng_uint8         iAlphaFilter,
                                                         mng_uint8         iAlphaInterlace,
                                                         mng_uint32        iCanvasstyle,
                                                         mng_getcanvasline fGetcanvasline);
   MNG_EXT mng_retcode MNG_DECL mng_updatemngheader     (mng_handle        hHandle,
                                                         mng_uint32        iFramecount,
                                                         mng_uint32        iLayercount,
                                                         mng_uint32        iPlaytime);
   MNG_EXT mng_retcode MNG_DECL mng_updatemngsimplicity (mng_handle        hHandle,
                                                         mng_uint32        iSimplicity);

   #===============================================================================

   */


