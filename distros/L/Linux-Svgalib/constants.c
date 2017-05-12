#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <vga.h>


/*  This stuff is just so ugly I had to put it in a separate file */

  
static double
constant_ACCELFLAG_PO(char *name, int len, int arg)
{
    if (12 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 2]) {
    case 'F':
	if (strEQ(name + 12, "LYFILLMODE")) {	/* ACCELFLAG_PO removed */
#ifdef ACCELFLAG_POLYFILLMODE
	    return ACCELFLAG_POLYFILLMODE;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 12, "LYHLINE")) {	/* ACCELFLAG_PO removed */
#ifdef ACCELFLAG_POLYHLINE
	    return ACCELFLAG_POLYHLINE;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 12, "LYLINE")) {	/* ACCELFLAG_PO removed */
#ifdef ACCELFLAG_POLYLINE
	    return ACCELFLAG_POLYLINE;
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
constant_ACCELFLAG_PU(char *name, int len, int arg)
{
    if (12 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 1]) {
    case 'B':
	if (strEQ(name + 12, "TBITMAP")) {	/* ACCELFLAG_PU removed */
#ifdef ACCELFLAG_PUTBITMAP
	    return ACCELFLAG_PUTBITMAP;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 12, "TIMAGE")) {	/* ACCELFLAG_PU removed */
#ifdef ACCELFLAG_PUTIMAGE
	    return ACCELFLAG_PUTIMAGE;
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
constant_ACCELFLAG_P(char *name, int len, int arg)
{
    switch (name[11 + 0]) {
    case 'O':
	return constant_ACCELFLAG_PO(name, len, arg);
    case 'U':
	return constant_ACCELFLAG_PU(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_ACCELFLAG_SC(char *name, int len, int arg)
{
    if (12 + 8 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 8]) {
    case '\0':
	if (strEQ(name + 12, "REENCOPY")) {	/* ACCELFLAG_SC removed */
#ifdef ACCELFLAG_SCREENCOPY
	    return ACCELFLAG_SCREENCOPY;
#else
	    goto not_there;
#endif
	}
    case 'B':
	if (strEQ(name + 12, "REENCOPYBITMAP")) {	/* ACCELFLAG_SC removed */
#ifdef ACCELFLAG_SCREENCOPYBITMAP
	    return ACCELFLAG_SCREENCOPYBITMAP;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 12, "REENCOPYMONO")) {	/* ACCELFLAG_SC removed */
#ifdef ACCELFLAG_SCREENCOPYMONO
	    return ACCELFLAG_SCREENCOPYMONO;
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
constant_ACCELFLAG_SE(char *name, int len, int arg)
{
    if (12 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 1]) {
    case 'B':
	if (strEQ(name + 12, "TBGCOLOR")) {	/* ACCELFLAG_SE removed */
#ifdef ACCELFLAG_SETBGCOLOR
	    return ACCELFLAG_SETBGCOLOR;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 12, "TFGCOLOR")) {	/* ACCELFLAG_SE removed */
#ifdef ACCELFLAG_SETFGCOLOR
	    return ACCELFLAG_SETFGCOLOR;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 12, "TMODE")) {	/* ACCELFLAG_SE removed */
#ifdef ACCELFLAG_SETMODE
	    return ACCELFLAG_SETMODE;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 12, "TOFFSET")) {	/* ACCELFLAG_SE removed */
#ifdef ACCELFLAG_SETOFFSET
	    return ACCELFLAG_SETOFFSET;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 12, "TRASTEROP")) {	/* ACCELFLAG_SE removed */
#ifdef ACCELFLAG_SETRASTEROP
	    return ACCELFLAG_SETRASTEROP;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 12, "TTRANSPARENCY")) {	/* ACCELFLAG_SE removed */
#ifdef ACCELFLAG_SETTRANSPARENCY
	    return ACCELFLAG_SETTRANSPARENCY;
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
constant_ACCELFLAG_S(char *name, int len, int arg)
{
    switch (name[11 + 0]) {
    case 'C':
	return constant_ACCELFLAG_SC(name, len, arg);
    case 'E':
	return constant_ACCELFLAG_SE(name, len, arg);
    case 'Y':
	if (strEQ(name + 11, "YNC")) {	/* ACCELFLAG_S removed */
#ifdef ACCELFLAG_SYNC
	    return ACCELFLAG_SYNC;
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
constant_ACCELFLAG_D(char *name, int len, int arg)
{
    if (11 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 3]) {
    case 'H':
	if (strEQ(name + 11, "RAWHLINELIST")) {	/* ACCELFLAG_D removed */
#ifdef ACCELFLAG_DRAWHLINELIST
	    return ACCELFLAG_DRAWHLINELIST;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 11, "RAWLINE")) {	/* ACCELFLAG_D removed */
#ifdef ACCELFLAG_DRAWLINE
	    return ACCELFLAG_DRAWLINE;
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
constant_ACCELF(char *name, int len, int arg)
{
    if (6 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 4]) {
    case 'D':
	if (!strnEQ(name + 6,"LAG_", 4))
	    break;
	return constant_ACCELFLAG_D(name, len, arg);
    case 'F':
	if (strEQ(name + 6, "LAG_FILLBOX")) {	/* ACCELF removed */
#ifdef ACCELFLAG_FILLBOX
	    return ACCELFLAG_FILLBOX;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (!strnEQ(name + 6,"LAG_", 4))
	    break;
	return constant_ACCELFLAG_P(name, len, arg);
    case 'S':
	if (!strnEQ(name + 6,"LAG_", 4))
	    break;
	return constant_ACCELFLAG_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_ACCEL_PO(char *name, int len, int arg)
{
    if (8 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 2]) {
    case 'F':
	if (strEQ(name + 8, "LYFILLMODE")) {	/* ACCEL_PO removed */
#ifdef ACCEL_POLYFILLMODE
	    return ACCEL_POLYFILLMODE;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 8, "LYHLINE")) {	/* ACCEL_PO removed */
#ifdef ACCEL_POLYHLINE
	    return ACCEL_POLYHLINE;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 8, "LYLINE")) {	/* ACCEL_PO removed */
#ifdef ACCEL_POLYLINE
	    return ACCEL_POLYLINE;
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
constant_ACCEL_PU(char *name, int len, int arg)
{
    if (8 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 1]) {
    case 'B':
	if (strEQ(name + 8, "TBITMAP")) {	/* ACCEL_PU removed */
#ifdef ACCEL_PUTBITMAP
	    return ACCEL_PUTBITMAP;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 8, "TIMAGE")) {	/* ACCEL_PU removed */
#ifdef ACCEL_PUTIMAGE
	    return ACCEL_PUTIMAGE;
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
constant_ACCEL_P(char *name, int len, int arg)
{
    switch (name[7 + 0]) {
    case 'O':
	return constant_ACCEL_PO(name, len, arg);
    case 'U':
	return constant_ACCEL_PU(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_ACCEL_SC(char *name, int len, int arg)
{
    if (8 + 8 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 8]) {
    case '\0':
	if (strEQ(name + 8, "REENCOPY")) {	/* ACCEL_SC removed */
#ifdef ACCEL_SCREENCOPY
	    return ACCEL_SCREENCOPY;
#else
	    goto not_there;
#endif
	}
    case 'B':
	if (strEQ(name + 8, "REENCOPYBITMAP")) {	/* ACCEL_SC removed */
#ifdef ACCEL_SCREENCOPYBITMAP
	    return ACCEL_SCREENCOPYBITMAP;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 8, "REENCOPYMONO")) {	/* ACCEL_SC removed */
#ifdef ACCEL_SCREENCOPYMONO
	    return ACCEL_SCREENCOPYMONO;
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
constant_ACCEL_SE(char *name, int len, int arg)
{
    if (8 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 1]) {
    case 'B':
	if (strEQ(name + 8, "TBGCOLOR")) {	/* ACCEL_SE removed */
#ifdef ACCEL_SETBGCOLOR
	    return ACCEL_SETBGCOLOR;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 8, "TFGCOLOR")) {	/* ACCEL_SE removed */
#ifdef ACCEL_SETFGCOLOR
	    return ACCEL_SETFGCOLOR;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 8, "TMODE")) {	/* ACCEL_SE removed */
#ifdef ACCEL_SETMODE
	    return ACCEL_SETMODE;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 8, "TOFFSET")) {	/* ACCEL_SE removed */
#ifdef ACCEL_SETOFFSET
	    return ACCEL_SETOFFSET;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 8, "TRASTEROP")) {	/* ACCEL_SE removed */
#ifdef ACCEL_SETRASTEROP
	    return ACCEL_SETRASTEROP;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 8, "TTRANSPARENCY")) {	/* ACCEL_SE removed */
#ifdef ACCEL_SETTRANSPARENCY
	    return ACCEL_SETTRANSPARENCY;
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
constant_ACCEL_S(char *name, int len, int arg)
{
    switch (name[7 + 0]) {
    case 'C':
	return constant_ACCEL_SC(name, len, arg);
    case 'E':
	return constant_ACCEL_SE(name, len, arg);
    case 'T':
	if (strEQ(name + 7, "TART")) {	/* ACCEL_S removed */
#ifdef ACCEL_START
	    return ACCEL_START;
#else
	    goto not_there;
#endif
	}
    case 'Y':
	if (strEQ(name + 7, "YNC")) {	/* ACCEL_S removed */
#ifdef ACCEL_SYNC
	    return ACCEL_SYNC;
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
constant_ACCEL_D(char *name, int len, int arg)
{
    if (7 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 3]) {
    case 'H':
	if (strEQ(name + 7, "RAWHLINELIST")) {	/* ACCEL_D removed */
#ifdef ACCEL_DRAWHLINELIST
	    return ACCEL_DRAWHLINELIST;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 7, "RAWLINE")) {	/* ACCEL_D removed */
#ifdef ACCEL_DRAWLINE
	    return ACCEL_DRAWLINE;
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
constant_ACCEL_(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'D':
	return constant_ACCEL_D(name, len, arg);
    case 'E':
	if (strEQ(name + 6, "END")) {	/* ACCEL_ removed */
#ifdef ACCEL_END
	    return ACCEL_END;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 6, "FILLBOX")) {	/* ACCEL_ removed */
#ifdef ACCEL_FILLBOX
	    return ACCEL_FILLBOX;
#else
	    goto not_there;
#endif
	}
    case 'P':
	return constant_ACCEL_P(name, len, arg);
    case 'S':
	return constant_ACCEL_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_AC(char *name, int len, int arg)
{
    if (2 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 3]) {
    case 'F':
	if (!strnEQ(name + 2,"CEL", 3))
	    break;
	return constant_ACCELF(name, len, arg);
    case '_':
	if (!strnEQ(name + 2,"CEL", 3))
	    break;
	return constant_ACCEL_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_A(char *name, int len, int arg)
{
    switch (name[1 + 0]) {
    case 'C':
	return constant_AC(name, len, arg);
    case 'L':
	if (strEQ(name + 1, "LI")) {	/* A removed */
#ifdef ALI
	    return ALI;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 1, "PM")) {	/* A removed */
#ifdef APM
	    return APM;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 1, "RK")) {	/* A removed */
#ifdef ARK
	    return ARK;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 1, "TI")) {	/* A removed */
#ifdef ATI
	    return ATI;
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
constant_BL(char *name, int len, int arg)
{
    if (2 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 4]) {
    case 'I':
	if (strEQ(name + 2, "ITS_IN_BACKGROUND")) {	/* BL removed */
#ifdef BLITS_IN_BACKGROUND
	    return BLITS_IN_BACKGROUND;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 2, "ITS_SYNC")) {	/* BL removed */
#ifdef BLITS_SYNC
	    return BLITS_SYNC;
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
constant_B(char *name, int len, int arg)
{
    switch (name[1 + 0]) {
    case 'A':
	if (strEQ(name + 1, "ANSHEE")) {	/* B removed */
#ifdef BANSHEE
	    return BANSHEE;
#else
	    goto not_there;
#endif
	}
    case 'L':
	return constant_BL(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_C(char *name, int len, int arg)
{
    switch (name[1 + 0]) {
    case 'A':
	if (strEQ(name + 1, "APABLE_LINEAR")) {	/* C removed */
#ifdef CAPABLE_LINEAR
	    return CAPABLE_LINEAR;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 1, "HIPS")) {	/* C removed */
#ifdef CHIPS
	    return CHIPS;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 1, "IRRUS")) {	/* C removed */
#ifdef CIRRUS
	    return CIRRUS;
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
constant_D(char *name, int len, int arg)
{
    if (1 + 7 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 7]) {
    case 'B':
	if (strEQ(name + 1, "ISABLE_BITMAP_TRANSPARENCY")) {	/* D removed */
#ifdef DISABLE_BITMAP_TRANSPARENCY
	    return DISABLE_BITMAP_TRANSPARENCY;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 1, "ISABLE_TRANSPARENCY_COLOR")) {	/* D removed */
#ifdef DISABLE_TRANSPARENCY_COLOR
	    return DISABLE_TRANSPARENCY_COLOR;
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
constant_EN(char *name, int len, int arg)
{
    if (2 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 5]) {
    case 'B':
	if (strEQ(name + 2, "ABLE_BITMAP_TRANSPARENCY")) {	/* EN removed */
#ifdef ENABLE_BITMAP_TRANSPARENCY
	    return ENABLE_BITMAP_TRANSPARENCY;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (strEQ(name + 2, "ABLE_TRANSPARENCY_COLOR")) {	/* EN removed */
#ifdef ENABLE_TRANSPARENCY_COLOR
	    return ENABLE_TRANSPARENCY_COLOR;
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
constant_ET(char *name, int len, int arg)
{
    switch (name[2 + 0]) {
    case '3':
	if (strEQ(name + 2, "3000")) {	/* ET removed */
#ifdef ET3000
	    return ET3000;
#else
	    goto not_there;
#endif
	}
    case '4':
	if (strEQ(name + 2, "4000")) {	/* ET removed */
#ifdef ET4000
	    return ET4000;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 2, "6000")) {	/* ET removed */
#ifdef ET6000
	    return ET6000;
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
constant_E(char *name, int len, int arg)
{
    switch (name[1 + 0]) {
    case 'G':
	if (strEQ(name + 1, "GA")) {	/* E removed */
#ifdef EGA
	    return EGA;
#else
	    goto not_there;
#endif
	}
    case 'N':
	return constant_EN(name, len, arg);
    case 'T':
	return constant_ET(name, len, arg);
    case 'X':
	if (strEQ(name + 1, "XT_INFO_AVAILABLE")) {	/* E removed */
#ifdef EXT_INFO_AVAILABLE
	    return EXT_INFO_AVAILABLE;
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
constant_G1800x1012x1(char *name, int len, int arg)
{
    if (12 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 2]) {
    case '\0':
	if (strEQ(name + 12, "6M")) {	/* G1800x1012x1 removed */
#ifdef G1800x1012x16M
	    return G1800x1012x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 12, "6M32")) {	/* G1800x1012x1 removed */
#ifdef G1800x1012x16M32
	    return G1800x1012x16M32;
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
constant_G18(char *name, int len, int arg)
{
    if (3 + 8 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 8]) {
    case '1':
	if (!strnEQ(name + 3,"00x1012x", 8))
	    break;
	return constant_G1800x1012x1(name, len, arg);
    case '2':
	if (strEQ(name + 3, "00x1012x256")) {	/* G18 removed */
#ifdef G1800x1012x256
	    return G1800x1012x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 3, "00x1012x32K")) {	/* G18 removed */
#ifdef G1800x1012x32K
	    return G1800x1012x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 3, "00x1012x64K")) {	/* G18 removed */
#ifdef G1800x1012x64K
	    return G1800x1012x64K;
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
constant_G1072x600x1(char *name, int len, int arg)
{
    if (11 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 2]) {
    case '\0':
	if (strEQ(name + 11, "6M")) {	/* G1072x600x1 removed */
#ifdef G1072x600x16M
	    return G1072x600x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 11, "6M32")) {	/* G1072x600x1 removed */
#ifdef G1072x600x16M32
	    return G1072x600x16M32;
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
constant_G107(char *name, int len, int arg)
{
    if (4 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 6]) {
    case '1':
	if (!strnEQ(name + 4,"2x600x", 6))
	    break;
	return constant_G1072x600x1(name, len, arg);
    case '2':
	if (strEQ(name + 4, "2x600x256")) {	/* G107 removed */
#ifdef G1072x600x256
	    return G1072x600x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 4, "2x600x32K")) {	/* G107 removed */
#ifdef G1072x600x32K
	    return G1072x600x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 4, "2x600x64K")) {	/* G107 removed */
#ifdef G1072x600x64K
	    return G1072x600x64K;
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
constant_G1024x768x16M(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case '\0':
	if (strEQ(name + 13, "")) {	/* G1024x768x16M removed */
#ifdef G1024x768x16M
	    return G1024x768x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 13, "32")) {	/* G1024x768x16M removed */
#ifdef G1024x768x16M32
	    return G1024x768x16M32;
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
constant_G1024x768x1(char *name, int len, int arg)
{
    if (11 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 1]) {
    case '\0':
	if (strEQ(name + 11, "6")) {	/* G1024x768x1 removed */
#ifdef G1024x768x16
	    return G1024x768x16;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 11,"6", 1))
	    break;
	return constant_G1024x768x16M(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G102(char *name, int len, int arg)
{
    if (4 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 6]) {
    case '1':
	if (!strnEQ(name + 4,"4x768x", 6))
	    break;
	return constant_G1024x768x1(name, len, arg);
    case '2':
	if (strEQ(name + 4, "4x768x256")) {	/* G102 removed */
#ifdef G1024x768x256
	    return G1024x768x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 4, "4x768x32K")) {	/* G102 removed */
#ifdef G1024x768x32K
	    return G1024x768x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 4, "4x768x64K")) {	/* G102 removed */
#ifdef G1024x768x64K
	    return G1024x768x64K;
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
constant_G10(char *name, int len, int arg)
{
    switch (name[3 + 0]) {
    case '2':
	return constant_G102(name, len, arg);
    case '7':
	return constant_G107(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G1920x1080x1(char *name, int len, int arg)
{
    if (12 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 2]) {
    case '\0':
	if (strEQ(name + 12, "6M")) {	/* G1920x1080x1 removed */
#ifdef G1920x1080x16M
	    return G1920x1080x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 12, "6M32")) {	/* G1920x1080x1 removed */
#ifdef G1920x1080x16M32
	    return G1920x1080x16M32;
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
constant_G1920x10(char *name, int len, int arg)
{
    if (8 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case '1':
	if (!strnEQ(name + 8,"80x", 3))
	    break;
	return constant_G1920x1080x1(name, len, arg);
    case '2':
	if (strEQ(name + 8, "80x256")) {	/* G1920x10 removed */
#ifdef G1920x1080x256
	    return G1920x1080x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 8, "80x32K")) {	/* G1920x10 removed */
#ifdef G1920x1080x32K
	    return G1920x1080x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 8, "80x64K")) {	/* G1920x10 removed */
#ifdef G1920x1080x64K
	    return G1920x1080x64K;
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
constant_G1920x1440x1(char *name, int len, int arg)
{
    if (12 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 2]) {
    case '\0':
	if (strEQ(name + 12, "6M")) {	/* G1920x1440x1 removed */
#ifdef G1920x1440x16M
	    return G1920x1440x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 12, "6M32")) {	/* G1920x1440x1 removed */
#ifdef G1920x1440x16M32
	    return G1920x1440x16M32;
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
constant_G1920x14(char *name, int len, int arg)
{
    if (8 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case '1':
	if (!strnEQ(name + 8,"40x", 3))
	    break;
	return constant_G1920x1440x1(name, len, arg);
    case '2':
	if (strEQ(name + 8, "40x256")) {	/* G1920x14 removed */
#ifdef G1920x1440x256
	    return G1920x1440x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 8, "40x32K")) {	/* G1920x14 removed */
#ifdef G1920x1440x32K
	    return G1920x1440x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 8, "40x64K")) {	/* G1920x14 removed */
#ifdef G1920x1440x64K
	    return G1920x1440x64K;
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
constant_G19(char *name, int len, int arg)
{
    if (3 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 4]) {
    case '0':
	if (!strnEQ(name + 3,"20x1", 4))
	    break;
	return constant_G1920x10(name, len, arg);
    case '4':
	if (!strnEQ(name + 3,"20x1", 4))
	    break;
	return constant_G1920x14(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G1152x864x16M(char *name, int len, int arg)
{
    switch (name[13 + 0]) {
    case '\0':
	if (strEQ(name + 13, "")) {	/* G1152x864x16M removed */
#ifdef G1152x864x16M
	    return G1152x864x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 13, "32")) {	/* G1152x864x16M removed */
#ifdef G1152x864x16M32
	    return G1152x864x16M32;
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
constant_G1152x864x1(char *name, int len, int arg)
{
    if (11 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 1]) {
    case '\0':
	if (strEQ(name + 11, "6")) {	/* G1152x864x1 removed */
#ifdef G1152x864x16
	    return G1152x864x16;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 11,"6", 1))
	    break;
	return constant_G1152x864x16M(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G11(char *name, int len, int arg)
{
    if (3 + 7 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 7]) {
    case '1':
	if (!strnEQ(name + 3,"52x864x", 7))
	    break;
	return constant_G1152x864x1(name, len, arg);
    case '2':
	if (strEQ(name + 3, "52x864x256")) {	/* G11 removed */
#ifdef G1152x864x256
	    return G1152x864x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 3, "52x864x32K")) {	/* G11 removed */
#ifdef G1152x864x32K
	    return G1152x864x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 3, "52x864x64K")) {	/* G11 removed */
#ifdef G1152x864x64K
	    return G1152x864x64K;
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
constant_G1280x720x1(char *name, int len, int arg)
{
    if (11 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 2]) {
    case '\0':
	if (strEQ(name + 11, "6M")) {	/* G1280x720x1 removed */
#ifdef G1280x720x16M
	    return G1280x720x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 11, "6M32")) {	/* G1280x720x1 removed */
#ifdef G1280x720x16M32
	    return G1280x720x16M32;
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
constant_G1280x7(char *name, int len, int arg)
{
    if (7 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 3]) {
    case '1':
	if (!strnEQ(name + 7,"20x", 3))
	    break;
	return constant_G1280x720x1(name, len, arg);
    case '2':
	if (strEQ(name + 7, "20x256")) {	/* G1280x7 removed */
#ifdef G1280x720x256
	    return G1280x720x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 7, "20x32K")) {	/* G1280x7 removed */
#ifdef G1280x720x32K
	    return G1280x720x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 7, "20x64K")) {	/* G1280x7 removed */
#ifdef G1280x720x64K
	    return G1280x720x64K;
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
constant_G1280x1024x16M(char *name, int len, int arg)
{
    switch (name[14 + 0]) {
    case '\0':
	if (strEQ(name + 14, "")) {	/* G1280x1024x16M removed */
#ifdef G1280x1024x16M
	    return G1280x1024x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 14, "32")) {	/* G1280x1024x16M removed */
#ifdef G1280x1024x16M32
	    return G1280x1024x16M32;
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
constant_G1280x1024x1(char *name, int len, int arg)
{
    if (12 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 1]) {
    case '\0':
	if (strEQ(name + 12, "6")) {	/* G1280x1024x1 removed */
#ifdef G1280x1024x16
	    return G1280x1024x16;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 12,"6", 1))
	    break;
	return constant_G1280x1024x16M(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G1280x1(char *name, int len, int arg)
{
    if (7 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 4]) {
    case '1':
	if (!strnEQ(name + 7,"024x", 4))
	    break;
	return constant_G1280x1024x1(name, len, arg);
    case '2':
	if (strEQ(name + 7, "024x256")) {	/* G1280x1 removed */
#ifdef G1280x1024x256
	    return G1280x1024x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 7, "024x32K")) {	/* G1280x1 removed */
#ifdef G1280x1024x32K
	    return G1280x1024x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 7, "024x64K")) {	/* G1280x1 removed */
#ifdef G1280x1024x64K
	    return G1280x1024x64K;
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
constant_G12(char *name, int len, int arg)
{
    if (3 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 3]) {
    case '1':
	if (!strnEQ(name + 3,"80x", 3))
	    break;
	return constant_G1280x1(name, len, arg);
    case '7':
	if (!strnEQ(name + 3,"80x", 3))
	    break;
	return constant_G1280x7(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G1360x768x1(char *name, int len, int arg)
{
    if (11 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 2]) {
    case '\0':
	if (strEQ(name + 11, "6M")) {	/* G1360x768x1 removed */
#ifdef G1360x768x16M
	    return G1360x768x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 11, "6M32")) {	/* G1360x768x1 removed */
#ifdef G1360x768x16M32
	    return G1360x768x16M32;
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
constant_G13(char *name, int len, int arg)
{
    if (3 + 7 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 7]) {
    case '1':
	if (!strnEQ(name + 3,"60x768x", 7))
	    break;
	return constant_G1360x768x1(name, len, arg);
    case '2':
	if (strEQ(name + 3, "60x768x256")) {	/* G13 removed */
#ifdef G1360x768x256
	    return G1360x768x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 3, "60x768x32K")) {	/* G13 removed */
#ifdef G1360x768x32K
	    return G1360x768x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 3, "60x768x64K")) {	/* G13 removed */
#ifdef G1360x768x64K
	    return G1360x768x64K;
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
constant_G1600x1200x16M(char *name, int len, int arg)
{
    switch (name[14 + 0]) {
    case '\0':
	if (strEQ(name + 14, "")) {	/* G1600x1200x16M removed */
#ifdef G1600x1200x16M
	    return G1600x1200x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 14, "32")) {	/* G1600x1200x16M removed */
#ifdef G1600x1200x16M32
	    return G1600x1200x16M32;
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
constant_G1600x1200x1(char *name, int len, int arg)
{
    if (12 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 1]) {
    case '\0':
	if (strEQ(name + 12, "6")) {	/* G1600x1200x1 removed */
#ifdef G1600x1200x16
	    return G1600x1200x16;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 12,"6", 1))
	    break;
	return constant_G1600x1200x16M(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G16(char *name, int len, int arg)
{
    if (3 + 8 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 8]) {
    case '1':
	if (!strnEQ(name + 3,"00x1200x", 8))
	    break;
	return constant_G1600x1200x1(name, len, arg);
    case '2':
	if (strEQ(name + 3, "00x1200x256")) {	/* G16 removed */
#ifdef G1600x1200x256
	    return G1600x1200x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 3, "00x1200x32K")) {	/* G16 removed */
#ifdef G1600x1200x32K
	    return G1600x1200x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 3, "00x1200x64K")) {	/* G16 removed */
#ifdef G1600x1200x64K
	    return G1600x1200x64K;
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
constant_G1(char *name, int len, int arg)
{
    switch (name[2 + 0]) {
    case '0':
	return constant_G10(name, len, arg);
    case '1':
	return constant_G11(name, len, arg);
    case '2':
	return constant_G12(name, len, arg);
    case '3':
	return constant_G13(name, len, arg);
    case '6':
	return constant_G16(name, len, arg);
    case '8':
	return constant_G18(name, len, arg);
    case '9':
	return constant_G19(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G2048x1152x1(char *name, int len, int arg)
{
    if (12 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 2]) {
    case '\0':
	if (strEQ(name + 12, "6M")) {	/* G2048x1152x1 removed */
#ifdef G2048x1152x16M
	    return G2048x1152x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 12, "6M32")) {	/* G2048x1152x1 removed */
#ifdef G2048x1152x16M32
	    return G2048x1152x16M32;
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
constant_G2048x11(char *name, int len, int arg)
{
    if (8 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case '1':
	if (!strnEQ(name + 8,"52x", 3))
	    break;
	return constant_G2048x1152x1(name, len, arg);
    case '2':
	if (strEQ(name + 8, "52x256")) {	/* G2048x11 removed */
#ifdef G2048x1152x256
	    return G2048x1152x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 8, "52x32K")) {	/* G2048x11 removed */
#ifdef G2048x1152x32K
	    return G2048x1152x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 8, "52x64K")) {	/* G2048x11 removed */
#ifdef G2048x1152x64K
	    return G2048x1152x64K;
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
constant_G2048x1536x1(char *name, int len, int arg)
{
    if (12 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[12 + 2]) {
    case '\0':
	if (strEQ(name + 12, "6M")) {	/* G2048x1536x1 removed */
#ifdef G2048x1536x16M
	    return G2048x1536x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 12, "6M32")) {	/* G2048x1536x1 removed */
#ifdef G2048x1536x16M32
	    return G2048x1536x16M32;
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
constant_G2048x15(char *name, int len, int arg)
{
    if (8 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[8 + 3]) {
    case '1':
	if (!strnEQ(name + 8,"36x", 3))
	    break;
	return constant_G2048x1536x1(name, len, arg);
    case '2':
	if (strEQ(name + 8, "36x256")) {	/* G2048x15 removed */
#ifdef G2048x1536x256
	    return G2048x1536x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 8, "36x32K")) {	/* G2048x15 removed */
#ifdef G2048x1536x32K
	    return G2048x1536x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 8, "36x64K")) {	/* G2048x15 removed */
#ifdef G2048x1536x64K
	    return G2048x1536x64K;
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
constant_G2(char *name, int len, int arg)
{
    if (2 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 5]) {
    case '1':
	if (!strnEQ(name + 2,"048x1", 5))
	    break;
	return constant_G2048x11(name, len, arg);
    case '5':
	if (!strnEQ(name + 2,"048x1", 5))
	    break;
	return constant_G2048x15(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G320x200x16M(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case '\0':
	if (strEQ(name + 12, "")) {	/* G320x200x16M removed */
#ifdef G320x200x16M
	    return G320x200x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 12, "32")) {	/* G320x200x16M removed */
#ifdef G320x200x16M32
	    return G320x200x16M32;
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
constant_G320x200x1(char *name, int len, int arg)
{
    if (10 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 1]) {
    case '\0':
	if (strEQ(name + 10, "6")) {	/* G320x200x1 removed */
#ifdef G320x200x16
	    return G320x200x16;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 10,"6", 1))
	    break;
	return constant_G320x200x16M(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G320x20(char *name, int len, int arg)
{
    if (7 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 2]) {
    case '1':
	if (!strnEQ(name + 7,"0x", 2))
	    break;
	return constant_G320x200x1(name, len, arg);
    case '2':
	if (strEQ(name + 7, "0x256")) {	/* G320x20 removed */
#ifdef G320x200x256
	    return G320x200x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 7, "0x32K")) {	/* G320x20 removed */
#ifdef G320x200x32K
	    return G320x200x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 7, "0x64K")) {	/* G320x20 removed */
#ifdef G320x200x64K
	    return G320x200x64K;
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
constant_G320x240x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G320x240x1 removed */
#ifdef G320x240x16M
	    return G320x240x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G320x240x1 removed */
#ifdef G320x240x16M32
	    return G320x240x16M32;
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
constant_G320x240x2(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "56")) {	/* G320x240x2 removed */
#ifdef G320x240x256
	    return G320x240x256;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 10, "56V")) {	/* G320x240x2 removed */
#ifdef G320x240x256V
	    return G320x240x256V;
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
constant_G320x24(char *name, int len, int arg)
{
    if (7 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 2]) {
    case '1':
	if (!strnEQ(name + 7,"0x", 2))
	    break;
	return constant_G320x240x1(name, len, arg);
    case '2':
	if (!strnEQ(name + 7,"0x", 2))
	    break;
	return constant_G320x240x2(name, len, arg);
    case '3':
	if (strEQ(name + 7, "0x32K")) {	/* G320x24 removed */
#ifdef G320x240x32K
	    return G320x240x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 7, "0x64K")) {	/* G320x24 removed */
#ifdef G320x240x64K
	    return G320x240x64K;
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
constant_G320x2(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case '0':
	return constant_G320x20(name, len, arg);
    case '4':
	return constant_G320x24(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G320x480x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G320x480x1 removed */
#ifdef G320x480x16M
	    return G320x480x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G320x480x1 removed */
#ifdef G320x480x16M32
	    return G320x480x16M32;
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
constant_G320x48(char *name, int len, int arg)
{
    if (7 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 2]) {
    case '1':
	if (!strnEQ(name + 7,"0x", 2))
	    break;
	return constant_G320x480x1(name, len, arg);
    case '2':
	if (strEQ(name + 7, "0x256")) {	/* G320x48 removed */
#ifdef G320x480x256
	    return G320x480x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 7, "0x32K")) {	/* G320x48 removed */
#ifdef G320x480x32K
	    return G320x480x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 7, "0x64K")) {	/* G320x48 removed */
#ifdef G320x480x64K
	    return G320x480x64K;
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
constant_G320x400x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G320x400x1 removed */
#ifdef G320x400x16M
	    return G320x400x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G320x400x1 removed */
#ifdef G320x400x16M32
	    return G320x400x16M32;
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
constant_G320x400x2(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "56")) {	/* G320x400x2 removed */
#ifdef G320x400x256
	    return G320x400x256;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 10, "56V")) {	/* G320x400x2 removed */
#ifdef G320x400x256V
	    return G320x400x256V;
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
constant_G320x40(char *name, int len, int arg)
{
    if (7 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 2]) {
    case '1':
	if (!strnEQ(name + 7,"0x", 2))
	    break;
	return constant_G320x400x1(name, len, arg);
    case '2':
	if (!strnEQ(name + 7,"0x", 2))
	    break;
	return constant_G320x400x2(name, len, arg);
    case '3':
	if (strEQ(name + 7, "0x32K")) {	/* G320x40 removed */
#ifdef G320x400x32K
	    return G320x400x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 7, "0x64K")) {	/* G320x40 removed */
#ifdef G320x400x64K
	    return G320x400x64K;
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
constant_G320x4(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case '0':
	return constant_G320x40(name, len, arg);
    case '8':
	return constant_G320x48(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G32(char *name, int len, int arg)
{
    if (3 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 2]) {
    case '2':
	if (!strnEQ(name + 3,"0x", 2))
	    break;
	return constant_G320x2(name, len, arg);
    case '4':
	if (!strnEQ(name + 3,"0x", 2))
	    break;
	return constant_G320x4(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G3(char *name, int len, int arg)
{
    switch (name[2 + 0]) {
    case '2':
	return constant_G32(name, len, arg);
    case '6':
	if (strEQ(name + 2, "60x480x256")) {	/* G3 removed */
#ifdef G360x480x256
	    return G360x480x256;
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
constant_G400x300x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G400x300x1 removed */
#ifdef G400x300x16M
	    return G400x300x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G400x300x1 removed */
#ifdef G400x300x16M32
	    return G400x300x16M32;
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
constant_G400x3(char *name, int len, int arg)
{
    if (6 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case '1':
	if (!strnEQ(name + 6,"00x", 3))
	    break;
	return constant_G400x300x1(name, len, arg);
    case '2':
	if (strEQ(name + 6, "00x256")) {	/* G400x3 removed */
#ifdef G400x300x256
	    return G400x300x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 6, "00x32K")) {	/* G400x3 removed */
#ifdef G400x300x32K
	    return G400x300x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 6, "00x64K")) {	/* G400x3 removed */
#ifdef G400x300x64K
	    return G400x300x64K;
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
constant_G400x600x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G400x600x1 removed */
#ifdef G400x600x16M
	    return G400x600x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G400x600x1 removed */
#ifdef G400x600x16M32
	    return G400x600x16M32;
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
constant_G400x6(char *name, int len, int arg)
{
    if (6 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case '1':
	if (!strnEQ(name + 6,"00x", 3))
	    break;
	return constant_G400x600x1(name, len, arg);
    case '2':
	if (strEQ(name + 6, "00x256")) {	/* G400x6 removed */
#ifdef G400x600x256
	    return G400x600x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 6, "00x32K")) {	/* G400x6 removed */
#ifdef G400x600x32K
	    return G400x600x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 6, "00x64K")) {	/* G400x6 removed */
#ifdef G400x600x64K
	    return G400x600x64K;
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
constant_G4(char *name, int len, int arg)
{
    if (2 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 3]) {
    case '3':
	if (!strnEQ(name + 2,"00x", 3))
	    break;
	return constant_G400x3(name, len, arg);
    case '6':
	if (!strnEQ(name + 2,"00x", 3))
	    break;
	return constant_G400x6(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G512x384x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G512x384x1 removed */
#ifdef G512x384x16M
	    return G512x384x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G512x384x1 removed */
#ifdef G512x384x16M32
	    return G512x384x16M32;
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
constant_G512x3(char *name, int len, int arg)
{
    if (6 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case '1':
	if (!strnEQ(name + 6,"84x", 3))
	    break;
	return constant_G512x384x1(name, len, arg);
    case '2':
	if (strEQ(name + 6, "84x256")) {	/* G512x3 removed */
#ifdef G512x384x256
	    return G512x384x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 6, "84x32K")) {	/* G512x3 removed */
#ifdef G512x384x32K
	    return G512x384x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 6, "84x64K")) {	/* G512x3 removed */
#ifdef G512x384x64K
	    return G512x384x64K;
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
constant_G512x480x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G512x480x1 removed */
#ifdef G512x480x16M
	    return G512x480x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G512x480x1 removed */
#ifdef G512x480x16M32
	    return G512x480x16M32;
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
constant_G512x4(char *name, int len, int arg)
{
    if (6 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case '1':
	if (!strnEQ(name + 6,"80x", 3))
	    break;
	return constant_G512x480x1(name, len, arg);
    case '2':
	if (strEQ(name + 6, "80x256")) {	/* G512x4 removed */
#ifdef G512x480x256
	    return G512x480x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 6, "80x32K")) {	/* G512x4 removed */
#ifdef G512x480x32K
	    return G512x480x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 6, "80x64K")) {	/* G512x4 removed */
#ifdef G512x480x64K
	    return G512x480x64K;
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
constant_G5(char *name, int len, int arg)
{
    if (2 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 3]) {
    case '3':
	if (!strnEQ(name + 2,"12x", 3))
	    break;
	return constant_G512x3(name, len, arg);
    case '4':
	if (!strnEQ(name + 2,"12x", 3))
	    break;
	return constant_G512x4(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G640x480x16M(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case '\0':
	if (strEQ(name + 12, "")) {	/* G640x480x16M removed */
#ifdef G640x480x16M
	    return G640x480x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 12, "32")) {	/* G640x480x16M removed */
#ifdef G640x480x16M32
	    return G640x480x16M32;
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
constant_G640x480x1(char *name, int len, int arg)
{
    if (10 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 1]) {
    case '\0':
	if (strEQ(name + 10, "6")) {	/* G640x480x1 removed */
#ifdef G640x480x16
	    return G640x480x16;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 10,"6", 1))
	    break;
	return constant_G640x480x16M(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G640x480x2(char *name, int len, int arg)
{
    switch (name[10 + 0]) {
    case '\0':
	if (strEQ(name + 10, "")) {	/* G640x480x2 removed */
#ifdef G640x480x2
	    return G640x480x2;
#else
	    goto not_there;
#endif
	}
    case '5':
	if (strEQ(name + 10, "56")) {	/* G640x480x2 removed */
#ifdef G640x480x256
	    return G640x480x256;
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
constant_G640x48(char *name, int len, int arg)
{
    if (7 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 2]) {
    case '1':
	if (!strnEQ(name + 7,"0x", 2))
	    break;
	return constant_G640x480x1(name, len, arg);
    case '2':
	if (!strnEQ(name + 7,"0x", 2))
	    break;
	return constant_G640x480x2(name, len, arg);
    case '3':
	if (strEQ(name + 7, "0x32K")) {	/* G640x48 removed */
#ifdef G640x480x32K
	    return G640x480x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 7, "0x64K")) {	/* G640x48 removed */
#ifdef G640x480x64K
	    return G640x480x64K;
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
constant_G640x400x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G640x400x1 removed */
#ifdef G640x400x16M
	    return G640x400x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G640x400x1 removed */
#ifdef G640x400x16M32
	    return G640x400x16M32;
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
constant_G640x40(char *name, int len, int arg)
{
    if (7 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[7 + 2]) {
    case '1':
	if (!strnEQ(name + 7,"0x", 2))
	    break;
	return constant_G640x400x1(name, len, arg);
    case '2':
	if (strEQ(name + 7, "0x256")) {	/* G640x40 removed */
#ifdef G640x400x256
	    return G640x400x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 7, "0x32K")) {	/* G640x40 removed */
#ifdef G640x400x32K
	    return G640x400x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 7, "0x64K")) {	/* G640x40 removed */
#ifdef G640x400x64K
	    return G640x400x64K;
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
constant_G640x4(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case '0':
	return constant_G640x40(name, len, arg);
    case '8':
	return constant_G640x48(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G6(char *name, int len, int arg)
{
    if (2 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 3]) {
    case '2':
	if (strEQ(name + 2, "40x200x16")) {	/* G6 removed */
#ifdef G640x200x16
	    return G640x200x16;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 2, "40x350x16")) {	/* G6 removed */
#ifdef G640x350x16
	    return G640x350x16;
#else
	    goto not_there;
#endif
	}
    case '4':
	if (!strnEQ(name + 2,"40x", 3))
	    break;
	return constant_G640x4(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G720x540x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G720x540x1 removed */
#ifdef G720x540x16M
	    return G720x540x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G720x540x1 removed */
#ifdef G720x540x16M32
	    return G720x540x16M32;
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
constant_G720x5(char *name, int len, int arg)
{
    if (6 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 3]) {
    case '1':
	if (!strnEQ(name + 6,"40x", 3))
	    break;
	return constant_G720x540x1(name, len, arg);
    case '2':
	if (strEQ(name + 6, "40x256")) {	/* G720x5 removed */
#ifdef G720x540x256
	    return G720x540x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 6, "40x32K")) {	/* G720x5 removed */
#ifdef G720x540x32K
	    return G720x540x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 6, "40x64K")) {	/* G720x5 removed */
#ifdef G720x540x64K
	    return G720x540x64K;
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
constant_G7(char *name, int len, int arg)
{
    if (2 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 3]) {
    case '3':
	if (strEQ(name + 2, "20x348x2")) {	/* G7 removed */
#ifdef G720x348x2
	    return G720x348x2;
#else
	    goto not_there;
#endif
	}
    case '5':
	if (!strnEQ(name + 2,"20x", 3))
	    break;
	return constant_G720x5(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G800x600x16M(char *name, int len, int arg)
{
    switch (name[12 + 0]) {
    case '\0':
	if (strEQ(name + 12, "")) {	/* G800x600x16M removed */
#ifdef G800x600x16M
	    return G800x600x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 12, "32")) {	/* G800x600x16M removed */
#ifdef G800x600x16M32
	    return G800x600x16M32;
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
constant_G800x600x1(char *name, int len, int arg)
{
    if (10 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 1]) {
    case '\0':
	if (strEQ(name + 10, "6")) {	/* G800x600x1 removed */
#ifdef G800x600x16
	    return G800x600x16;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (!strnEQ(name + 10,"6", 1))
	    break;
	return constant_G800x600x16M(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G80(char *name, int len, int arg)
{
    if (3 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 6]) {
    case '1':
	if (!strnEQ(name + 3,"0x600x", 6))
	    break;
	return constant_G800x600x1(name, len, arg);
    case '2':
	if (strEQ(name + 3, "0x600x256")) {	/* G80 removed */
#ifdef G800x600x256
	    return G800x600x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 3, "0x600x32K")) {	/* G80 removed */
#ifdef G800x600x32K
	    return G800x600x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 3, "0x600x64K")) {	/* G80 removed */
#ifdef G800x600x64K
	    return G800x600x64K;
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
constant_G848x480x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G848x480x1 removed */
#ifdef G848x480x16M
	    return G848x480x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G848x480x1 removed */
#ifdef G848x480x16M32
	    return G848x480x16M32;
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
constant_G84(char *name, int len, int arg)
{
    if (3 + 6 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 6]) {
    case '1':
	if (!strnEQ(name + 3,"8x480x", 6))
	    break;
	return constant_G848x480x1(name, len, arg);
    case '2':
	if (strEQ(name + 3, "8x480x256")) {	/* G84 removed */
#ifdef G848x480x256
	    return G848x480x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 3, "8x480x32K")) {	/* G84 removed */
#ifdef G848x480x32K
	    return G848x480x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 3, "8x480x64K")) {	/* G84 removed */
#ifdef G848x480x64K
	    return G848x480x64K;
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
constant_G8(char *name, int len, int arg)
{
    switch (name[2 + 0]) {
    case '0':
	return constant_G80(name, len, arg);
    case '4':
	return constant_G84(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_G960x720x1(char *name, int len, int arg)
{
    if (10 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[10 + 2]) {
    case '\0':
	if (strEQ(name + 10, "6M")) {	/* G960x720x1 removed */
#ifdef G960x720x16M
	    return G960x720x16M;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 10, "6M32")) {	/* G960x720x1 removed */
#ifdef G960x720x16M32
	    return G960x720x16M32;
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
constant_G9(char *name, int len, int arg)
{
    if (2 + 7 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 7]) {
    case '1':
	if (!strnEQ(name + 2,"60x720x", 7))
	    break;
	return constant_G960x720x1(name, len, arg);
    case '2':
	if (strEQ(name + 2, "60x720x256")) {	/* G9 removed */
#ifdef G960x720x256
	    return G960x720x256;
#else
	    goto not_there;
#endif
	}
    case '3':
	if (strEQ(name + 2, "60x720x32K")) {	/* G9 removed */
#ifdef G960x720x32K
	    return G960x720x32K;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 2, "60x720x64K")) {	/* G9 removed */
#ifdef G960x720x64K
	    return G960x720x64K;
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
constant_G(char *name, int len, int arg)
{
    switch (name[1 + 0]) {
    case '1':
	return constant_G1(name, len, arg);
    case '2':
	return constant_G2(name, len, arg);
    case '3':
	return constant_G3(name, len, arg);
    case '4':
	return constant_G4(name, len, arg);
    case '5':
	return constant_G5(name, len, arg);
    case '6':
	return constant_G6(name, len, arg);
    case '7':
	return constant_G7(name, len, arg);
    case '8':
	return constant_G8(name, len, arg);
    case '9':
	return constant_G9(name, len, arg);
    case 'L':
	if (strEQ(name + 1, "LASTMODE")) {	/* G removed */
#ifdef GLASTMODE
	    return GLASTMODE;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 1, "VGA6400")) {	/* G removed */
#ifdef GVGA6400
	    return GVGA6400;
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
constant_HAVE_B(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'I':
	if (strEQ(name + 6, "ITBLIT")) {	/* HAVE_B removed */
#ifdef HAVE_BITBLIT
	    return HAVE_BITBLIT;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 6, "LITWAIT")) {	/* HAVE_B removed */
#ifdef HAVE_BLITWAIT
	    return HAVE_BLITWAIT;
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
constant_H(char *name, int len, int arg)
{
    if (1 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 4]) {
    case 'B':
	if (!strnEQ(name + 1,"AVE_", 4))
	    break;
	return constant_HAVE_B(name, len, arg);
    case 'E':
	if (strEQ(name + 1, "AVE_EXT_SET")) {	/* H removed */
#ifdef HAVE_EXT_SET
	    return HAVE_EXT_SET;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 1, "AVE_FILLBLIT")) {	/* H removed */
#ifdef HAVE_FILLBLIT
	    return HAVE_FILLBLIT;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 1, "AVE_HLINELISTBLIT")) {	/* H removed */
#ifdef HAVE_HLINELISTBLIT
	    return HAVE_HLINELISTBLIT;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 1, "AVE_IMAGEBLIT")) {	/* H removed */
#ifdef HAVE_IMAGEBLIT
	    return HAVE_IMAGEBLIT;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 1, "AVE_RWPAGE")) {	/* H removed */
#ifdef HAVE_RWPAGE
	    return HAVE_RWPAGE;
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
constant_I(char *name, int len, int arg)
{
    if (1 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 2]) {
    case 'D':
	if (strEQ(name + 1, "S_DYNAMICMODE")) {	/* I removed */
#ifdef IS_DYNAMICMODE
	    return IS_DYNAMICMODE;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 1, "S_INTERLACED")) {	/* I removed */
#ifdef IS_INTERLACED
	    return IS_INTERLACED;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 1, "S_LINEAR")) {	/* I removed */
#ifdef IS_LINEAR
	    return IS_LINEAR;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 1, "S_MODEX")) {	/* I removed */
#ifdef IS_MODEX
	    return IS_MODEX;
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
constant_MON8(char *name, int len, int arg)
{
    if (4 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 3]) {
    case '5':
	if (strEQ(name + 4, "00_56")) {	/* MON8 removed */
#ifdef MON800_56
	    return MON800_56;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 4, "00_60")) {	/* MON8 removed */
#ifdef MON800_60
	    return MON800_60;
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
constant_MON1024_7(char *name, int len, int arg)
{
    switch (name[9 + 0]) {
    case '0':
	if (strEQ(name + 9, "0")) {	/* MON1024_7 removed */
#ifdef MON1024_70
	    return MON1024_70;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 9, "2")) {	/* MON1024_7 removed */
#ifdef MON1024_72
	    return MON1024_72;
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
constant_MON1(char *name, int len, int arg)
{
    if (4 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 4]) {
    case '4':
	if (strEQ(name + 4, "024_43I")) {	/* MON1 removed */
#ifdef MON1024_43I
	    return MON1024_43I;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 4, "024_60")) {	/* MON1 removed */
#ifdef MON1024_60
	    return MON1024_60;
#else
	    goto not_there;
#endif
	}
    case '7':
	if (!strnEQ(name + 4,"024_", 4))
	    break;
	return constant_MON1024_7(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MO(char *name, int len, int arg)
{
    if (2 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 1]) {
    case '1':
	if (!strnEQ(name + 2,"N", 1))
	    break;
	return constant_MON1(name, len, arg);
    case '6':
	if (strEQ(name + 2, "N640_60")) {	/* MO removed */
#ifdef MON640_60
	    return MON640_60;
#else
	    goto not_there;
#endif
	}
    case '8':
	if (!strnEQ(name + 2,"N", 1))
	    break;
	return constant_MON8(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MA(char *name, int len, int arg)
{
    if (2 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 2]) {
    case '3':
	if (strEQ(name + 2, "CH32")) {	/* MA removed */
#ifdef MACH32
	    return MACH32;
#else
	    goto not_there;
#endif
	}
    case '6':
	if (strEQ(name + 2, "CH64")) {	/* MA removed */
#ifdef MACH64
	    return MACH64;
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
constant_M(char *name, int len, int arg)
{
    switch (name[1 + 0]) {
    case 'A':
	return constant_MA(name, len, arg);
    case 'O':
	return constant_MO(name, len, arg);
    case 'X':
	if (strEQ(name + 1, "X")) {	/* M removed */
#ifdef MX
	    return MX;
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
constant_RO(char *name, int len, int arg)
{
    if (2 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 2]) {
    case 'A':
	if (strEQ(name + 2, "P_AND")) {	/* RO removed */
#ifdef ROP_AND
	    return ROP_AND;
#else
	    goto not_there;
#endif
	}
    case 'C':
	if (strEQ(name + 2, "P_COPY")) {	/* RO removed */
#ifdef ROP_COPY
	    return ROP_COPY;
#else
	    goto not_there;
#endif
	}
    case 'I':
	if (strEQ(name + 2, "P_INVERT")) {	/* RO removed */
#ifdef ROP_INVERT
	    return ROP_INVERT;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 2, "P_OR")) {	/* RO removed */
#ifdef ROP_OR
	    return ROP_OR;
#else
	    goto not_there;
#endif
	}
    case 'X':
	if (strEQ(name + 2, "P_XOR")) {	/* RO removed */
#ifdef ROP_XOR
	    return ROP_XOR;
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
constant_R(char *name, int len, int arg)
{
    switch (name[1 + 0]) {
    case 'A':
	if (strEQ(name + 1, "AGE")) {	/* R removed */
#ifdef RAGE
	    return RAGE;
#else
	    goto not_there;
#endif
	}
    case 'G':
	if (strEQ(name + 1, "GB_MISORDERED")) {	/* R removed */
#ifdef RGB_MISORDERED
	    return RGB_MISORDERED;
#else
	    goto not_there;
#endif
	}
    case 'O':
	return constant_RO(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_T(char *name, int len, int arg)
{
    switch (name[1 + 0]) {
    case 'E':
	if (strEQ(name + 1, "EXT")) {	/* T removed */
#ifdef TEXT
	    return TEXT;
#else
	    goto not_there;
#endif
	}
    case 'V':
	if (strEQ(name + 1, "VGA8900")) {	/* T removed */
#ifdef TVGA8900
	    return TVGA8900;
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
constant_VGA_AVAIL_R(char *name, int len, int arg)
{
    if (11 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 2]) {
    case '\0':
	if (strEQ(name + 11, "OP")) {	/* VGA_AVAIL_R removed */
#ifdef VGA_AVAIL_ROP
	    return VGA_AVAIL_ROP;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 11, "OPMODES")) {	/* VGA_AVAIL_R removed */
#ifdef VGA_AVAIL_ROPMODES
	    return VGA_AVAIL_ROPMODES;
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
constant_VGA_AVAIL_T(char *name, int len, int arg)
{
    if (11 + 4 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[11 + 4]) {
    case 'M':
	if (strEQ(name + 11, "RANSMODES")) {	/* VGA_AVAIL_T removed */
#ifdef VGA_AVAIL_TRANSMODES
	    return VGA_AVAIL_TRANSMODES;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 11, "RANSPARENCY")) {	/* VGA_AVAIL_T removed */
#ifdef VGA_AVAIL_TRANSPARENCY
	    return VGA_AVAIL_TRANSPARENCY;
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
constant_VGA_A(char *name, int len, int arg)
{
    if (5 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 5]) {
    case 'A':
	if (strEQ(name + 5, "VAIL_ACCEL")) {	/* VGA_A removed */
#ifdef VGA_AVAIL_ACCEL
	    return VGA_AVAIL_ACCEL;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 5, "VAIL_FLAGS")) {	/* VGA_A removed */
#ifdef VGA_AVAIL_FLAGS
	    return VGA_AVAIL_FLAGS;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (!strnEQ(name + 5,"VAIL_", 5))
	    break;
	return constant_VGA_AVAIL_R(name, len, arg);
    case 'S':
	if (strEQ(name + 5, "VAIL_SET")) {	/* VGA_A removed */
#ifdef VGA_AVAIL_SET
	    return VGA_AVAIL_SET;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (!strnEQ(name + 5,"VAIL_", 5))
	    break;
	return constant_VGA_AVAIL_T(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_VGA_C(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'L':
	if (strEQ(name + 5, "LUT8")) {	/* VGA_C removed */
#ifdef VGA_CLUT8
	    return VGA_CLUT8;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 5, "OMEFROMBACK")) {	/* VGA_C removed */
#ifdef VGA_COMEFROMBACK
	    return VGA_COMEFROMBACK;
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
constant_VGA_E(char *name, int len, int arg)
{
    if (5 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[5 + 3]) {
    case 'A':
	if (strEQ(name + 5, "XT_AVAILABLE")) {	/* VGA_E removed */
#ifdef VGA_EXT_AVAILABLE
	    return VGA_EXT_AVAILABLE;
#else
	    goto not_there;
#endif
	}
    case 'C':
	if (strEQ(name + 5, "XT_CLEAR")) {	/* VGA_E removed */
#ifdef VGA_EXT_CLEAR
	    return VGA_EXT_CLEAR;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 5, "XT_FONT_SIZE")) {	/* VGA_E removed */
#ifdef VGA_EXT_FONT_SIZE
	    return VGA_EXT_FONT_SIZE;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 5, "XT_PAGE_OFFSET")) {	/* VGA_E removed */
#ifdef VGA_EXT_PAGE_OFFSET
	    return VGA_EXT_PAGE_OFFSET;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 5, "XT_RESET")) {	/* VGA_E removed */
#ifdef VGA_EXT_RESET
	    return VGA_EXT_RESET;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 5, "XT_SET")) {	/* VGA_E removed */
#ifdef VGA_EXT_SET
	    return VGA_EXT_SET;
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
constant_VGA_(char *name, int len, int arg)
{
    switch (name[4 + 0]) {
    case 'A':
	return constant_VGA_A(name, len, arg);
    case 'C':
	return constant_VGA_C(name, len, arg);
    case 'E':
	return constant_VGA_E(name, len, arg);
    case 'G':
	if (strEQ(name + 4, "GOTOBACK")) {	/* VGA_ removed */
#ifdef VGA_GOTOBACK
	    return VGA_GOTOBACK;
#else
	    goto not_there;
#endif
	}
    case 'H':
	if (strEQ(name + 4, "H")) {	/* VGA_ removed */
#ifdef VGA_H
	    return 1;
#else
	    goto not_there;
#endif
	}
    case 'K':
	if (strEQ(name + 4, "KEYEVENT")) {	/* VGA_ removed */
#ifdef VGA_KEYEVENT
	    return VGA_KEYEVENT;
#else
	    goto not_there;
#endif
	}
    case 'M':
	if (strEQ(name + 4, "MOUSEEVENT")) {	/* VGA_ removed */
#ifdef VGA_MOUSEEVENT
	    return VGA_MOUSEEVENT;
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
constant_VG(char *name, int len, int arg)
{
    if (2 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[2 + 1]) {
    case '\0':
	if (strEQ(name + 2, "A")) {	/* VG removed */
#ifdef VGA
	    return VGA;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 2,"A", 1))
	    break;
	return constant_VGA_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_V(char *name, int len, int arg)
{
    switch (name[1 + 0]) {
    case 'E':
	if (strEQ(name + 1, "ESA")) {	/* V removed */
#ifdef VESA
	    return VESA;
#else
	    goto not_there;
#endif
	}
    case 'G':
	return constant_VG(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

double
_constant(char *name, int len, int arg)
{
    errno = 0;
    switch (name[0 + 0]) {
    case 'A':
	return constant_A(name, len, arg);
    case 'B':
	return constant_B(name, len, arg);
    case 'C':
	return constant_C(name, len, arg);
    case 'D':
	return constant_D(name, len, arg);
    case 'E':
	return constant_E(name, len, arg);
    case 'G':
	return constant_G(name, len, arg);
    case 'H':
	return constant_H(name, len, arg);
    case 'I':
	return constant_I(name, len, arg);
    case 'M':
	return constant_M(name, len, arg);
    case 'N':
	if (strEQ(name + 0, "NV3")) {	/*  removed */
#ifdef NV3
	    return NV3;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 0, "OAK")) {	/*  removed */
#ifdef OAK
	    return OAK;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 0, "PARADISE")) {	/*  removed */
#ifdef PARADISE
	    return PARADISE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	return constant_R(name, len, arg);
    case 'S':
	if (strEQ(name + 0, "S3")) {	/*  removed */
#ifdef S3
	    return S3;
#else
	    goto not_there;
#endif
	}
    case 'T':
	return constant_T(name, len, arg);
    case 'U':
	if (strEQ(name + 0, "UNDEFINED")) {	/*  removed */
#ifdef UNDEFINED
	    return UNDEFINED;
#else
	    goto not_there;
#endif
	}
    case 'V':
	return constant_V(name, len, arg);
    case '_':
	if (strEQ(name + 0, "__GLASTMODE")) {	/*  removed */
#ifdef __GLASTMODE
	    return __GLASTMODE;
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

