/* This is "plot.h", the public header file for GNU libplot, a shared
   library for 2-dimensional vector graphics. */

/* stdio.h must be included before this file is included. */

/* This file is written for ANSI C compilers.  If you use it with a
   pre-ANSI C compiler that does not support the `const' keyword, such as
   the `cc' compiler supplied with SunOS (i.e., Solaris 1.x), you should
   use the -DNO_CONST_SUPPORT option when compiling your code. */

#ifndef _PLOT_H_
#define _PLOT_H_ 1

/***********************************************************************/

/* This version of plot.h accompanies GNU libplot version 2.0 */
#define LIBPLOT_VERSION "2.0"

/* support C++ */
#ifdef __BEGIN_DECLS
#undef __BEGIN_DECLS
#endif
#ifdef __END_DECLS
#undef __END_DECLS
#endif
#ifdef __cplusplus
# define __BEGIN_DECLS extern "C" {
# define __END_DECLS }
#else
# define __BEGIN_DECLS		/* empty */
# define __END_DECLS		/* empty */
#endif
     
/* ___P is a macro used to wrap function prototypes, so that compilers that
   don't understand ANSI C prototypes still work, and ANSI C compilers can
   issue warnings about type mismatches. */
#ifdef ___P
#undef ___P
#endif
#if defined (__STDC__) || defined (_AIX) \
	|| (defined (__mips) && defined (_SYSTYPE_SVR4)) \
	|| defined(WIN32) || defined(__cplusplus)
#define ___P(protos) protos
#else
#define ___P(protos) ()
#endif

/* For old compilers (e.g. SunOS) */
#ifdef ___const
#undef ___const
#endif
#ifdef NO_CONST_SUPPORT
#define ___const
#else
#define ___const const
#endif

__BEGIN_DECLS

/* THE C API */

/* THE GLOBAL FUNCTIONS IN GNU LIBPLOT */
/* There are 92 basic functions, plus 4 that are specific to the C binding */

/* 13 functions in traditional (pre-GNU) libplot */
int pl_arc ___P((int xc, int yc, int x0, int y0, int x1, int y1));
int pl_box ___P((int x0, int y0, int x1, int y1)); /* no op code, originally */
int pl_circle ___P((int x, int y, int r));
int pl_closepl ___P((void));	/* no op code, originally */
int pl_cont ___P((int x, int y));
int pl_erase ___P((void));
int pl_label ___P((___const char *s));
int pl_line ___P((int x0, int y0, int x1, int y1));
int pl_linemod ___P((___const char *s));
int pl_move ___P((int x, int y));
int pl_openpl ___P((void));	/* no op code, originally */
int pl_point ___P((int x, int y));
int pl_space ___P((int x0, int y0, int x1, int y1));

/* 42 additional functions in GNU libplot, plus an obsolescent one */
FILE* pl_outfile ___P((FILE* outfile));/* OBSOLESCENT */
int pl_alabel ___P((int x_justify, int y_justify, ___const char *s));
int pl_arcrel ___P((int dxc, int dyc, int dx0, int dy0, int dx1, int dy1));
int pl_bezier2 ___P((int x0, int y0, int x1, int y1, int x2, int y2));
int pl_bezier2rel ___P((int dx0, int dy0, int dx1, int dy1, int dx2, int dy2));
int pl_bezier3 ___P((int x0, int y0, int x1, int y1, int x2, int y2, int x3, int y3));
int pl_bezier3rel ___P((int dx0, int dy0, int dx1, int dy1, int dx2, int dy2, int dx3, int dy3));
int pl_bgcolor ___P((int red, int green, int blue));
int pl_bgcolorname ___P((___const char *name));
int pl_boxrel ___P((int dx0, int dy0, int dx1, int dy1));
int pl_capmod ___P((___const char *s));
int pl_circlerel ___P((int dx, int dy, int r));
int pl_color ___P((int red, int green, int blue));
int pl_colorname ___P((___const char *name));
int pl_contrel ___P((int x, int y));
int pl_ellarc ___P((int xc, int yc, int x0, int y0, int x1, int y1));
int pl_ellarcrel ___P((int dxc, int dyc, int dx0, int dy0, int dx1, int dy1));
int pl_ellipse ___P((int x, int y, int rx, int ry, int angle));
int pl_ellipserel ___P((int dx, int dy, int rx, int ry, int angle));
int pl_endpath ___P((void));
int pl_fillcolor ___P((int red, int green, int blue));
int pl_fillcolorname ___P((___const char *name));
int pl_fillmod ___P((___const char *s));
int pl_filltype ___P((int level));
int pl_flushpl ___P((void));
int pl_fontname ___P((___const char *s));
int pl_fontsize ___P((int size));
int pl_havecap ___P((___const char *s));
int pl_joinmod ___P((___const char *s));
int pl_labelwidth ___P((___const char *s));
int pl_linedash ___P((int n, const int *dashes, int offset));
int pl_linerel ___P((int dx0, int dy0, int dx1, int dy1));
int pl_linewidth ___P((int size));
int pl_marker ___P((int x, int y, int type, int size));
int pl_markerrel ___P((int dx, int dy, int type, int size));
int pl_moverel ___P((int x, int y));
int pl_pencolor ___P((int red, int green, int blue));
int pl_pencolorname ___P((___const char *name));
int pl_pointrel ___P((int dx, int dy));
int pl_restorestate ___P((void));
int pl_savestate ___P((void));
int pl_space2 ___P((int x0, int y0, int x1, int y1, int x2, int y2));
int pl_textangle ___P((int angle));

/* 32 floating point counterparts to some of the above (all GNU additions) */
double pl_ffontname ___P((___const char *s));
double pl_ffontsize ___P((double size));
double pl_flabelwidth ___P((___const char *s));
double pl_ftextangle ___P((double angle));
int pl_farc ___P((double xc, double yc, double x0, double y0, double x1, double y1));
int pl_farcrel ___P((double dxc, double dyc, double dx0, double dy0, double dx1, double dy1));
int pl_fbezier2 ___P((double x0, double y0, double x1, double y1, double x2, double y2));
int pl_fbezier2rel ___P((double dx0, double dy0, double dx1, double dy1, double dx2, double dy2));
int pl_fbezier3 ___P((double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3));
int pl_fbezier3rel ___P((double dx0, double dy0, double dx1, double dy1, double dx2, double dy2, double dx3, double dy3));
int pl_fbox ___P((double x0, double y0, double x1, double y1));
int pl_fboxrel ___P((double dx0, double dy0, double dx1, double dy1));
int pl_fcircle ___P((double x, double y, double r));
int pl_fcirclerel ___P((double dx, double dy, double r));
int pl_fcont ___P((double x, double y));
int pl_fcontrel ___P((double dx, double dy));
int pl_fellarc ___P((double xc, double yc, double x0, double y0, double x1, double y1));
int pl_fellarcrel ___P((double dxc, double dyc, double dx0, double dy0, double dx1, double dy1));
int pl_fellipse ___P((double x, double y, double rx, double ry, double angle));
int pl_fellipserel ___P((double dx, double dy, double rx, double ry, double angle));
int pl_flinedash ___P((int n, const double *dashes, double offset));
int pl_fline ___P((double x0, double y0, double x1, double y1));
int pl_flinerel ___P((double dx0, double dy0, double dx1, double dy1));
int pl_flinewidth ___P((double size));
int pl_fmarker ___P((double x, double y, int type, double size));
int pl_fmarkerrel ___P((double dx, double dy, int type, double size));
int pl_fmove ___P((double x, double y));
int pl_fmoverel ___P((double dx, double dy));
int pl_fpoint ___P((double x, double y));
int pl_fpointrel ___P((double dx, double dy));
int pl_fspace ___P((double x0, double y0, double x1, double y1));
int pl_fspace2 ___P((double x0, double y0, double x1, double y1, double x2, double y2));

/* 5 floating point operations with no integer counterpart (GNU additions) */
int pl_fconcat ___P((double m0, double m1, double m2, double m3, double m4, double m5));
int pl_fmiterlimit ___P((double limit));
int pl_frotate ___P((double theta));
int pl_fscale ___P((double x, double y));
int pl_ftranslate ___P((double x, double y));

/* 4 functions specific to the C binding (for construction/destruction of
   Plotters, and setting of Plotter parameters) */
int pl_newpl ___P((___const char *type, FILE *infile, FILE *outfile, FILE *errfile));
int pl_selectpl ___P((int handle));
int pl_deletepl ___P((int handle));
#ifdef NO_VOID_SUPPORT
int pl_parampl ___P((___const char *parameter, char *value));
#else
int pl_parampl ___P((___const char *parameter, void *value));
#endif

__END_DECLS

/* THE GLOBAL VARIABLES IN GNU LIBPLOT */
/* There are two; both are user-settable error handlers. */
extern int (*libplot_warning_handler) ___P((___const char *msg));
extern int (*libplot_error_handler) ___P((___const char *msg));

#undef ___const
#undef ___P

/***********************************************************************/

#ifndef _PLOTTER_H_	/* allow inclusion of both plot.h, plotter.h */

/* Symbol types for the marker() function, extending over the range 0..31.
   (1 through 5 are the same as in the GKS [Graphical Kernel System].)

   These are now defined as enums rather than ints.  Cast them to ints if
   necessary. */
enum 
{ M_NONE, M_DOT, M_PLUS, M_ASTERISK, M_CIRCLE, M_CROSS, 
  M_SQUARE, M_TRIANGLE, M_DIAMOND, M_STAR, M_INVERTED_TRIANGLE, 
  M_STARBURST, M_FANCY_PLUS, M_FANCY_CROSS, M_FANCY_SQUARE, 
  M_FANCY_DIAMOND, M_FILLED_CIRCLE, M_FILLED_SQUARE, M_FILLED_TRIANGLE, 
  M_FILLED_DIAMOND, M_FILLED_INVERTED_TRIANGLE, M_FILLED_FANCY_SQUARE,
  M_FILLED_FANCY_DIAMOND, M_HALF_FILLED_CIRCLE, M_HALF_FILLED_SQUARE,
  M_HALF_FILLED_TRIANGLE, M_HALF_FILLED_DIAMOND,
  M_HALF_FILLED_INVERTED_TRIANGLE, M_HALF_FILLED_FANCY_SQUARE,
  M_HALF_FILLED_FANCY_DIAMOND, M_OCTAGON, M_FILLED_OCTAGON 
};

/* ONE-BYTE OPERATION CODES FOR GNU METAFILE FORMAT. These are now defined
   as enums rather than ints.  Cast them to ints if necessary.

   There are 80 currently used op codes, including 30 that are used only in
   binary metafiles, not in portable metafiles. */

enum
{  
/* 10 op codes for primitive graphics operations, as in Unix plot(5) format. */
  O_ARC		=	'a',  
  O_CIRCLE	=	'c',  
  O_CONT	=	'n',
  O_ERASE	=	'e',
  O_LABEL	=	't',
  O_LINEMOD	=	'f',
  O_LINE	=	'l',
  O_MOVE	=	'm',
  O_POINT	=	'p',
  O_SPACE	=	's',
  
/* 38 op codes that are GNU extensions */
  O_ALABEL	=	'T',
  O_ARCREL	=	'A',
  O_BEZIER2	=       'q',
  O_BEZIER2REL	=       'r',
  O_BEZIER3	=       'y',
  O_BEZIER3REL	=       'z',
  O_BGCOLOR	=	'~',
  O_BOX		=	'B',	/* not an op code in Unix plot(5) */
  O_BOXREL	=	'H',
  O_CAPMOD	=	'K',
  O_CIRCLEREL	=	'G',
  O_CLOSEPL	=	'x',	/* not an op code in Unix plot(5) */
  O_COMMENT	=	'#',
  O_CONTREL	=	'N',
  O_ELLARC	=	'?',
  O_ELLARCREL	=	'/',
  O_ELLIPSE	=	'+',
  O_ELLIPSEREL	=	'=',
  O_ENDPATH	=	'E',
  O_FILLTYPE	=	'L',
  O_FILLCOLOR	=	'D',
  O_FILLMOD	=	'g',
  O_FONTNAME	=	'F',
  O_FONTSIZE	=	'S',
  O_JOINMOD	=	'J',
  O_LINEDASH	= 	'd',
  O_LINEREL	=	'I',
  O_LINEWIDTH	=	'W',
  O_MARKER	=	'Y',
  O_MARKERREL	=	'Z',
  O_MOVEREL	=	'M',
  O_OPENPL	=	'o',	/* not an op code in Unix plot(5) */
  O_PENCOLOR	=	'-',
  O_POINTREL	=	'P',
  O_RESTORESTATE=	'O',
  O_SAVESTATE	=	'U',
  O_SPACE2	=	':',
  O_TEXTANGLE	=	'R',

/* 30 floating point counterparts to some of the above.  Used only in
   binary GNU metafile format, not in portable (human-readable) metafile
   format, so they are not even slightly mnemonic. */
  O_FARC	=	'1',
  O_FARCREL	=	'2',
  O_FBEZIER2	=       '`',
  O_FBEZIER2REL	=       '\'',
  O_FBEZIER3	=       ',',
  O_FBEZIER3REL	=       '.',
  O_FBOX	=	'3',
  O_FBOXREL	=	'4',
  O_FCIRCLE	=	'5',
  O_FCIRCLEREL	=	'6',
  O_FCONT	=	')',
  O_FCONTREL	=	'_',
  O_FELLARC	=	'}',
  O_FELLARCREL	=	'|',
  O_FELLIPSE	=	'{',
  O_FELLIPSEREL	=	'[',
  O_FFONTSIZE	=	'7',
  O_FLINE	=	'8',
  O_FLINEDASH	= 	'w',
  O_FLINEREL	=	'9',
  O_FLINEWIDTH	=	'0',
  O_FMARKER	=	'!',
  O_FMARKERREL	=	'@',
  O_FMOVE	=	'$',
  O_FMOVEREL	=	'%',
  O_FPOINT	=	'^',
  O_FPOINTREL	=	'&',
  O_FSPACE	=	'*',
  O_FSPACE2	=	';',
  O_FTEXTANGLE	=	'(',

/* 2 op codes for floating point operations with no integer counterpart */
  O_FCONCAT		=	'\\',
  O_FMITERLIMIT		=	'i'
};

#endif /* not _PLOTTER_H_ */

/***********************************************************************/

#endif /* not _PLOT_H_ */
