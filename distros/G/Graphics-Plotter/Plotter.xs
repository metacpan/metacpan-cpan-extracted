/*
 * Plotter.xs (part of Graphics::Plotter perl module)
 * Date: Mar 22 1999
 * Version: 2.0
 * plotutils libplotter compatibility version: 2.2
 * Author: Piotr Klaban <amkler@man.torun.pl>
 */

#include <plotter.h>
/* workaround for do_open perl bug */
#ifdef do_open
#undef do_open
#endif
#ifdef do_close
#undef do_close
#endif
/* bool is defined by perl, useless in C++ */
#ifdef bool
#undef bool
#endif


#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static int
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'M':
	if (strEQ(name, "M_ASTERISK"))
	    return M_ASTERISK;
	if (strEQ(name, "M_CIRCLE"))
	    return M_CIRCLE;
	if (strEQ(name, "M_CROSS"))
	    return M_CROSS;
	if (strEQ(name, "M_DIAMOND"))
	    return M_DIAMOND;
	if (strEQ(name, "M_DOT"))
	    return M_DOT;
	if (strEQ(name, "M_FANCY_CROSS"))
	    return M_FANCY_CROSS;
	if (strEQ(name, "M_FANCY_DIAMOND"))
	    return M_FANCY_DIAMOND;
	if (strEQ(name, "M_FANCY_PLUS"))
	    return M_FANCY_PLUS;
	if (strEQ(name, "M_FANCY_SQUARE"))
	    return M_FANCY_SQUARE;
	if (strEQ(name, "M_FILLED_CIRCLE"))
	    return M_FILLED_CIRCLE;
	if (strEQ(name, "M_FILLED_DIAMOND"))
	    return M_FILLED_DIAMOND;
	if (strEQ(name, "M_FILLED_FANCY_DIAMOND"))
	    return M_FILLED_FANCY_DIAMOND;
	if (strEQ(name, "M_FILLED_FANCY_SQUARE"))
	    return M_FILLED_FANCY_SQUARE;
	if (strEQ(name, "M_FILLED_INVERTED_TRIANGLE"))
	    return M_FILLED_INVERTED_TRIANGLE;
	if (strEQ(name, "M_FILLED_OCTAGON"))
	    return M_FILLED_OCTAGON;
	if (strEQ(name, "M_FILLED_SQUARE"))
	    return M_FILLED_SQUARE;
	if (strEQ(name, "M_FILLED_TRIANGLE"))
	    return M_FILLED_TRIANGLE;
	if (strEQ(name, "M_HALF_FILLED_CIRCLE"))
	    return M_HALF_FILLED_CIRCLE;
	if (strEQ(name, "M_HALF_FILLED_DIAMOND"))
	    return M_HALF_FILLED_DIAMOND;
	if (strEQ(name, "M_HALF_FILLED_FANCY_DIAMOND"))
	    return M_HALF_FILLED_FANCY_DIAMOND;
	if (strEQ(name, "M_HALF_FILLED_FANCY_SQUARE"))
	    return M_HALF_FILLED_FANCY_SQUARE;
	if (strEQ(name, "M_HALF_FILLED_INVERTED_TRIANGLE"))
	    return M_HALF_FILLED_INVERTED_TRIANGLE;
	if (strEQ(name, "M_HALF_FILLED_SQUARE"))
	    return M_HALF_FILLED_SQUARE;
	if (strEQ(name, "M_HALF_FILLED_TRIANGLE"))
	    return M_HALF_FILLED_TRIANGLE;
	if (strEQ(name, "M_INVERTED_TRIANGLE"))
	    return M_INVERTED_TRIANGLE;
	if (strEQ(name, "M_OCTAGON"))
	    return M_OCTAGON;
	if (strEQ(name, "M_NONE"))
	    return M_NONE;
	if (strEQ(name, "M_PLUS"))
	    return M_PLUS;
	if (strEQ(name, "M_SQUARE"))
	    return M_SQUARE;
	if (strEQ(name, "M_STAR"))
	    return M_STAR;
	if (strEQ(name, "M_STARBURST"))
	    return M_STARBURST;
	if (strEQ(name, "M_TRIANGLE"))
	    return M_TRIANGLE;
	break;
    case 'O':
	if (strEQ(name, "O_ALABEL"))
	    return O_ALABEL;
	if (strEQ(name, "O_ARC"))
	    return O_ARC;
	if (strEQ(name, "O_ARCREL"))
	    return O_ARCREL;
	if (strEQ(name, "O_BEZIER2"))
	    return O_BEZIER2;
	if (strEQ(name, "O_BEZIER2REL"))
	    return O_BEZIER2REL;
	if (strEQ(name, "O_BEZIER3"))
	    return O_BEZIER3;
	if (strEQ(name, "O_BEZIER3REL"))
	    return O_BEZIER3REL;
	if (strEQ(name, "O_BGCOLOR"))
	    return O_BGCOLOR;
	if (strEQ(name, "O_BOX"))
	    return O_BOX;
	if (strEQ(name, "O_BOXREL"))
	    return O_BOXREL;
	if (strEQ(name, "O_CAPMOD"))
	    return O_CAPMOD;
	if (strEQ(name, "O_CIRCLE"))
	    return O_CIRCLE;
	if (strEQ(name, "O_CIRCLEREL"))
	    return O_CIRCLEREL;
	if (strEQ(name, "O_CLOSEPL"))
	    return O_CLOSEPL;
	if (strEQ(name, "O_COMMENT"))
	    return O_COMMENT;
	if (strEQ(name, "O_CONT"))
	    return O_CONT;
	if (strEQ(name, "O_CONTREL"))
	    return O_CONTREL;
	if (strEQ(name, "O_ELLARC"))
	    return O_ELLARC;
	if (strEQ(name, "O_ELLARCREL"))
	    return O_ELLARCREL;
	if (strEQ(name, "O_ELLIPSE"))
	    return O_ELLIPSE;
	if (strEQ(name, "O_ELLIPSEREL"))
	    return O_ELLIPSEREL;
	if (strEQ(name, "O_ENDPATH"))
	    return O_ENDPATH;
	if (strEQ(name, "O_ERASE"))
	    return O_ERASE;
	if (strEQ(name, "O_FARC"))
	    return O_FARC;
	if (strEQ(name, "O_FARCREL"))
	    return O_FARCREL;
	if (strEQ(name, "O_FBEZIER2"))
	    return O_FBEZIER2;
	if (strEQ(name, "O_FBEZIER2REL"))
	    return O_FBEZIER2REL;
	if (strEQ(name, "O_FBEZIER3"))
	    return O_FBEZIER3;
	if (strEQ(name, "O_FBEZIER3REL"))
	    return O_FBEZIER3REL;
	if (strEQ(name, "O_FBOX"))
	    return O_FBOX;
	if (strEQ(name, "O_FBOXREL"))
	    return O_FBOXREL;
	if (strEQ(name, "O_FCIRCLE"))
	    return O_FCIRCLE;
	if (strEQ(name, "O_FCIRCLEREL"))
	    return O_FCIRCLEREL;
	if (strEQ(name, "O_FCONCAT"))
	    return O_FCONCAT;
	if (strEQ(name, "O_FCONT"))
	    return O_FCONT;
	if (strEQ(name, "O_FCONTREL"))
	    return O_FCONTREL;
	if (strEQ(name, "O_FELLARC"))
	    return O_FELLARC;
	if (strEQ(name, "O_FELLARCREL"))
	    return O_FELLARCREL;
	if (strEQ(name, "O_FELLIPSE"))
	    return O_FELLIPSE;
	if (strEQ(name, "O_FELLIPSEREL"))
	    return O_FELLIPSEREL;
	if (strEQ(name, "O_FFONTSIZE"))
	    return O_FFONTSIZE;
	if (strEQ(name, "O_FILLTYPE"))
	    return O_FILLTYPE;
	if (strEQ(name, "O_FILLCOLOR"))
	    return O_FILLCOLOR;
	if (strEQ(name, "O_FILLMOD"))
	    return O_FILLMOD;
	if (strEQ(name, "O_FLINEDASH"))
	    return O_FLINEDASH;
	if (strEQ(name, "O_FLINE"))
	    return O_FLINE;
	if (strEQ(name, "O_FLINEREL"))
	    return O_FLINEREL;
	if (strEQ(name, "O_FLINEWIDTH"))
	    return O_FLINEWIDTH;
	if (strEQ(name, "O_FMARKER"))
	    return O_FMARKER;
	if (strEQ(name, "O_FMARKERREL"))
	    return O_FMARKERREL;
	if (strEQ(name, "O_FMITERLIMIT"))
	    return O_FMITERLIMIT;
	if (strEQ(name, "O_FMOVE"))
	    return O_FMOVE;
	if (strEQ(name, "O_FMOVEREL"))
	    return O_FMOVEREL;
	if (strEQ(name, "O_FONTNAME"))
	    return O_FONTNAME;
	if (strEQ(name, "O_FONTSIZE"))
	    return O_FONTSIZE;
	if (strEQ(name, "O_FPOINT"))
	    return O_FPOINT;
	if (strEQ(name, "O_FPOINTREL"))
	    return O_FPOINTREL;
	if (strEQ(name, "O_FSPACE"))
	    return O_FSPACE;
	if (strEQ(name, "O_FSPACE2"))
	    return O_FSPACE2;
	if (strEQ(name, "O_FTEXTANGLE"))
	    return O_FTEXTANGLE;
	if (strEQ(name, "O_JOINMOD"))
	    return O_JOINMOD;
	if (strEQ(name, "O_LABEL"))
	    return O_LABEL;
	if (strEQ(name, "O_LINE"))
	    return O_LINE;
	if (strEQ(name, "O_LINEDASH"))
	    return O_LINEDASH;
	if (strEQ(name, "O_LINEMOD"))
	    return O_LINEMOD;
	if (strEQ(name, "O_LINEREL"))
	    return O_LINEREL;
	if (strEQ(name, "O_LINEWIDTH"))
	    return O_LINEWIDTH;
	if (strEQ(name, "O_MARKER"))
	    return O_MARKER;
	if (strEQ(name, "O_MARKERREL"))
	    return O_MARKERREL;
	if (strEQ(name, "O_MOVE"))
	    return O_MOVE;
	if (strEQ(name, "O_MOVEREL"))
	    return O_MOVEREL;
	if (strEQ(name, "O_POINT"))
	    return O_POINT;
	if (strEQ(name, "O_POINTREL"))
	    return O_POINTREL;
	if (strEQ(name, "O_RESTORESTATE"))
	    return O_RESTORESTATE;
	if (strEQ(name, "O_SAVESTATE"))
	    return O_SAVESTATE;
	if (strEQ(name, "O_SPACE"))
	    return O_SPACE;
	if (strEQ(name, "O_SPACE2"))
	    return O_SPACE2;
	if (strEQ(name, "O_TEXTANGLE"))
	    return O_TEXTANGLE;
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static SV * keep_warning_handler = (SV*)NULL;

int
warning_handler_internal(const char *msg)
{
	char *tmp = (char *)msg;
	dSP ;
	
	PUSHMARK(sp);
	XPUSHs(sv_2mortal(newSVpv(tmp, 0)));
	PUTBACK ;
	perl_call_sv(keep_warning_handler, G_DISCARD);
}

static SV * keep_error_handler = (SV*)NULL;

int
error_handler_internal(const char *msg)
{
	char *tmp = (char *)msg;
	dSP ;
	
	PUSHMARK(sp);
	XPUSHs(sv_2mortal(newSVpv(tmp, 0)));
	PUTBACK ;
	perl_call_sv(keep_error_handler, G_DISCARD);
}

MODULE = Graphics::Plotter		PACKAGE = Graphics::Plotter

int
constant(name, arg)
	char	*	name;
	int		arg;

# value here could not be void because Perl has problem with that
# static function
static int
parampl(parameter,value)
	char	*	parameter;
	char	*	value;
	CODE:
	RETVAL = Plotter::parampl(parameter, value);
	OUTPUT:
	RETVAL

void
warning_handler(sub)
	SV *	sub;
	CODE:
	if (keep_warning_handler == (SV*)NULL) {
		keep_warning_handler = newSVsv(sub);
		pl_libplotter_warning_handler = &warning_handler_internal;
	} else
		SvSetSV(keep_warning_handler, sub);

void
error_handler(sub)
	SV *	sub;
	CODE:
	if (keep_error_handler == (SV*)NULL) {
		keep_error_handler = newSVsv(sub);
		pl_libplotter_error_handler = &error_handler_internal;
	} else
		SvSetSV(keep_error_handler, sub);

Plotter *
Plotter::new(infile,outfile,errfile)
	FILE	*	infile;
	FILE	*	outfile;
	FILE	*	errfile;

void
Plotter::DESTROY()

INCLUDE: funcxs

INCLUDE: perl newxs      Meta |
INCLUDE: perl newxs       Tek |
INCLUDE: perl newxs      HPGL |
INCLUDE: perl newxs       PCL |
INCLUDE: perl newxs       Fig |
INCLUDE: perl newxs        PS |
INCLUDE: perl newxs        AI |
INCLUDE: perl newxs       PNM |
INCLUDE: perl newxs       GIF |

#ifndef X_DISPLAY_MISSING

INCLUDE: perl newxs XDrawable |
INCLUDE: perl newxs         X |

#endif

