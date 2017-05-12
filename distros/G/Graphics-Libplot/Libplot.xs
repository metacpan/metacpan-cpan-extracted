#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <plot.h>

#define LIBPLOTPERL_VERSION "1.6"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	if (strEQ(name, "LIBPLOTPERL_VERSION"))
#ifdef LIBPLOTPERL_VERSION
/*	    return (LIBPLOTPERL_VERSION); */
#else
	    goto not_there;
#endif
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    case '_':
	if (strEQ(name, "__BEGIN_DECLS"))
#ifdef __BEGIN_DECLS
	    return __BEGIN_DECLS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "__END_DECLS"))
#ifdef __END_DECLS
	    return __END_DECLS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "___const"))
#ifdef ___const
	    return ___const;
#else
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Graphics::Libplot		PACKAGE = Graphics::Libplot


double
constant(name,arg)
	char *		name
	int		arg


#  int pl_arc ___P((int xc, int yc, int x0, int y0, int x1, int y1)); 
int
pl_arc(xc,yc,x0,y0,x1,y1)
      int  xc
      int  yc
      int  x0
      int  y0
      int  x1
      int  y1


#  int pl_box ___P((int x0, int y0, int x1, int y1)); /* no op code, originally */ 
int
pl_box(x0,y0,x1,y1)
      int  x0
      int  y0
      int  x1
      int  y1


#  int pl_circle ___P((int x, int y, int r)); 
int
pl_circle(x,y,r)
      int  x
      int  y
      int  r


#  int pl_closepl ___P((void));	/* no op code, originally */ 
int
pl_closepl()


#  int pl_cont ___P((int x, int y)); 
int
pl_cont(x,y)
      int  x
      int  y


#  int pl_erase ___P((void)); 
int
pl_erase()


#  int pl_label ___P((___const char *s)); 
int
pl_label(s)
      char  *s


#  int pl_line ___P((int x0, int y0, int x1, int y1)); 
int
pl_line(x0,y0,x1,y1)
      int  x0
      int  y0
      int  x1
      int  y1


#  int pl_linemod ___P((___const char *s)); 
int
pl_linemod(s)
      char  *s


#  int pl_move ___P((int x, int y)); 
int
pl_move(x,y)
      int  x
      int  y


#  int pl_openpl ___P((void));	/* no op code, originally */ 
int
pl_openpl()


#  int pl_point ___P((int x, int y)); 
int
pl_point(x,y)
      int  x
      int  y


#  int pl_space ___P((int x0, int y0, int x1, int y1)); 
int
pl_space(x0,y0,x1,y1)
      int  x0
      int  y0
      int  x1
      int  y1


#  FILE* pl_outfile ___P((FILE* outfile));/* OBSOLESCENT */ 
FILE*
pl_outfile(outfile)
      FILE*  outfile


#  int pl_alabel ___P((int x_justify, int y_justify, ___const char *s)); 
int
pl_alabel(x_justify,y_justify,s)
      int  x_justify
      int  y_justify
      char  *s


#  int pl_arcrel ___P((int dxc, int dyc, int dx0, int dy0, int dx1, int dy1)); 
int
pl_arcrel(dxc,dyc,dx0,dy0,dx1,dy1)
      int  dxc
      int  dyc
      int  dx0
      int  dy0
      int  dx1
      int  dy1


#  int pl_bezier2 ___P((int x0, int y0, int x1, int y1, int x2, int y2)); 
int
pl_bezier2(x0,y0,x1,y1,x2,y2)
      int  x0
      int  y0
      int  x1
      int  y1
      int  x2
      int  y2


#  int pl_bezier2rel ___P((int dx0, int dy0, int dx1, int dy1, int dx2, int dy2)); 
int
pl_bezier2rel(dx0,dy0,dx1,dy1,dx2,dy2)
      int  dx0
      int  dy0
      int  dx1
      int  dy1
      int  dx2
      int  dy2


#  int pl_bezier3 ___P((int x0, int y0, int x1, int y1, int x2, int y2, int x3, int y3)); 
int
pl_bezier3(x0,y0,x1,y1,x2,y2,x3,y3)
      int  x0
      int  y0
      int  x1
      int  y1
      int  x2
      int  y2
      int  x3
      int  y3


#  int pl_bezier3rel ___P((int dx0, int dy0, int dx1, int dy1, int dx2, int dy2, int dx3, int dy3)); 
int
pl_bezier3rel(dx0,dy0,dx1,dy1,dx2,dy2,dx3,dy3)
      int  dx0
      int  dy0
      int  dx1
      int  dy1
      int  dx2
      int  dy2
      int  dx3
      int  dy3


#  int pl_bgcolor ___P((int red, int green, int blue)); 
int
pl_bgcolor(red,green,blue)
      int  red
      int  green
      int  blue


#  int pl_bgcolorname ___P((___const char *name)); 
int
pl_bgcolorname(name)
      char  *name


#  int pl_boxrel ___P((int dx0, int dy0, int dx1, int dy1)); 
int
pl_boxrel(dx0,dy0,dx1,dy1)
      int  dx0
      int  dy0
      int  dx1
      int  dy1


#  int pl_capmod ___P((___const char *s)); 
int
pl_capmod(s)
      char  *s


#  int pl_circlerel ___P((int dx, int dy, int r)); 
int
pl_circlerel(dx,dy,r)
      int  dx
      int  dy
      int  r


#  int pl_color ___P((int red, int green, int blue)); 
int
pl_color(red,green,blue)
      int  red
      int  green
      int  blue


#  int pl_colorname ___P((___const char *name)); 
int
pl_colorname(name)
      char  *name


#  int pl_contrel ___P((int x, int y)); 
int
pl_contrel(x,y)
      int  x
      int  y


#  int pl_ellarc ___P((int xc, int yc, int x0, int y0, int x1, int y1)); 
int
pl_ellarc(xc,yc,x0,y0,x1,y1)
      int  xc
      int  yc
      int  x0
      int  y0
      int  x1
      int  y1


#  int pl_ellarcrel ___P((int dxc, int dyc, int dx0, int dy0, int dx1, int dy1)); 
int
pl_ellarcrel(dxc,dyc,dx0,dy0,dx1,dy1)
      int  dxc
      int  dyc
      int  dx0
      int  dy0
      int  dx1
      int  dy1


#  int pl_ellipse ___P((int x, int y, int rx, int ry, int angle)); 
int
pl_ellipse(x,y,rx,ry,angle)
      int  x
      int  y
      int  rx
      int  ry
      int  angle


#  int pl_ellipserel ___P((int dx, int dy, int rx, int ry, int angle)); 
int
pl_ellipserel(dx,dy,rx,ry,angle)
      int  dx
      int  dy
      int  rx
      int  ry
      int  angle


#  int pl_endpath ___P((void)); 
int
pl_endpath()


#  int pl_fillcolor ___P((int red, int green, int blue)); 
int
pl_fillcolor(red,green,blue)
      int  red
      int  green
      int  blue


#  int pl_fillcolorname ___P((___const char *name)); 
int
pl_fillcolorname(name)
      char  *name


#  int pl_fillmod ___P((___const char *s)); 
int
pl_fillmod(s)
      char  *s


#  int pl_filltype ___P((int level)); 
int
pl_filltype(level)
      int  level


#  int pl_flushpl ___P((void)); 
int
pl_flushpl()


#  int pl_fontname ___P((___const char *s)); 
int
pl_fontname(s)
      char  *s


#  int pl_fontsize ___P((int size)); 
int
pl_fontsize(size)
      int  size


#  int pl_havecap ___P((___const char *s)); 
int
pl_havecap(s)
      char  *s


#  int pl_joinmod ___P((___const char *s)); 
int
pl_joinmod(s)
      char  *s


#  int pl_labelwidth ___P((___const char *s)); 
int
pl_labelwidth(s)
      char  *s


#  int pl_linedash ___P((int n, const int *dashes, int offset)); 
int
pl_linedash(n,dashes,offset)
      int  n
      int  *dashes
      int  offset


#  int pl_linerel ___P((int dx0, int dy0, int dx1, int dy1)); 
int
pl_linerel(dx0,dy0,dx1,dy1)
      int  dx0
      int  dy0
      int  dx1
      int  dy1


#  int pl_linewidth ___P((int size)); 
int
pl_linewidth(size)
      int  size


#  int pl_marker ___P((int x, int y, int type, int size)); 
int
pl_marker(x,y,type,size)
      int  x
      int  y
      int  type
      int  size


#  int pl_markerrel ___P((int dx, int dy, int type, int size)); 
int
pl_markerrel(dx,dy,type,size)
      int  dx
      int  dy
      int  type
      int  size


#  int pl_moverel ___P((int x, int y)); 
int
pl_moverel(x,y)
      int  x
      int  y


#  int pl_pencolor ___P((int red, int green, int blue)); 
int
pl_pencolor(red,green,blue)
      int  red
      int  green
      int  blue


#  int pl_pencolorname ___P((___const char *name)); 
int
pl_pencolorname(name)
      char  *name


#  int pl_pointrel ___P((int dx, int dy)); 
int
pl_pointrel(dx,dy)
      int  dx
      int  dy


#  int pl_restorestate ___P((void)); 
int
pl_restorestate()


#  int pl_savestate ___P((void)); 
int
pl_savestate()


#  int pl_space2 ___P((int x0, int y0, int x1, int y1, int x2, int y2)); 
int
pl_space2(x0,y0,x1,y1,x2,y2)
      int  x0
      int  y0
      int  x1
      int  y1
      int  x2
      int  y2


#  int pl_textangle ___P((int angle)); 
int
pl_textangle(angle)
      int  angle


#  double pl_ffontname ___P((___const char *s)); 
double
pl_ffontname(s)
      char  *s


#  double pl_ffontsize ___P((double size)); 
double
pl_ffontsize(size)
      double  size


#  double pl_flabelwidth ___P((___const char *s)); 
double
pl_flabelwidth(s)
      char  *s


#  double pl_ftextangle ___P((double angle)); 
double
pl_ftextangle(angle)
      double  angle


#  int pl_farc ___P((double xc, double yc, double x0, double y0, double x1, double y1)); 
int
pl_farc(xc,yc,x0,y0,x1,y1)
      double  xc
      double  yc
      double  x0
      double  y0
      double  x1
      double  y1


#  int pl_farcrel ___P((double dxc, double dyc, double dx0, double dy0, double dx1, double dy1)); 
int
pl_farcrel(dxc,dyc,dx0,dy0,dx1,dy1)
      double  dxc
      double  dyc
      double  dx0
      double  dy0
      double  dx1
      double  dy1


#  int pl_fbezier2 ___P((double x0, double y0, double x1, double y1, double x2, double y2)); 
int
pl_fbezier2(x0,y0,x1,y1,x2,y2)
      double  x0
      double  y0
      double  x1
      double  y1
      double  x2
      double  y2


#  int pl_fbezier2rel ___P((double dx0, double dy0, double dx1, double dy1, double dx2, double dy2)); 
int
pl_fbezier2rel(dx0,dy0,dx1,dy1,dx2,dy2)
      double  dx0
      double  dy0
      double  dx1
      double  dy1
      double  dx2
      double  dy2


#  int pl_fbezier3 ___P((double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3)); 
int
pl_fbezier3(x0,y0,x1,y1,x2,y2,x3,y3)
      double  x0
      double  y0
      double  x1
      double  y1
      double  x2
      double  y2
      double  x3
      double  y3


#  int pl_fbezier3rel ___P((double dx0, double dy0, double dx1, double dy1, double dx2, double dy2, double dx3, double dy3)); 
int
pl_fbezier3rel(dx0,dy0,dx1,dy1,dx2,dy2,dx3,dy3)
      double  dx0
      double  dy0
      double  dx1
      double  dy1
      double  dx2
      double  dy2
      double  dx3
      double  dy3


#  int pl_fbox ___P((double x0, double y0, double x1, double y1)); 
int
pl_fbox(x0,y0,x1,y1)
      double  x0
      double  y0
      double  x1
      double  y1


#  int pl_fboxrel ___P((double dx0, double dy0, double dx1, double dy1)); 
int
pl_fboxrel(dx0,dy0,dx1,dy1)
      double  dx0
      double  dy0
      double  dx1
      double  dy1


#  int pl_fcircle ___P((double x, double y, double r)); 
int
pl_fcircle(x,y,r)
      double  x
      double  y
      double  r


#  int pl_fcirclerel ___P((double dx, double dy, double r)); 
int
pl_fcirclerel(dx,dy,r)
      double  dx
      double  dy
      double  r


#  int pl_fcont ___P((double x, double y)); 
int
pl_fcont(x,y)
      double  x
      double  y


#  int pl_fcontrel ___P((double dx, double dy)); 
int
pl_fcontrel(dx,dy)
      double  dx
      double  dy


#  int pl_fellarc ___P((double xc, double yc, double x0, double y0, double x1, double y1)); 
int
pl_fellarc(xc,yc,x0,y0,x1,y1)
      double  xc
      double  yc
      double  x0
      double  y0
      double  x1
      double  y1


#  int pl_fellarcrel ___P((double dxc, double dyc, double dx0, double dy0, double dx1, double dy1)); 
int
pl_fellarcrel(dxc,dyc,dx0,dy0,dx1,dy1)
      double  dxc
      double  dyc
      double  dx0
      double  dy0
      double  dx1
      double  dy1


#  int pl_fellipse ___P((double x, double y, double rx, double ry, double angle)); 
int
pl_fellipse(x,y,rx,ry,angle)
      double  x
      double  y
      double  rx
      double  ry
      double  angle


#  int pl_fellipserel ___P((double dx, double dy, double rx, double ry, double angle)); 
int
pl_fellipserel(dx,dy,rx,ry,angle)
      double  dx
      double  dy
      double  rx
      double  ry
      double  angle


#  int pl_flinedash ___P((int n, const double *dashes, double offset)); 
int
pl_flinedash(n,dashes,offset)
      int  n
      double *dashes
      double  offset


#  int pl_fline ___P((double x0, double y0, double x1, double y1)); 
int
pl_fline(x0,y0,x1,y1)
      double  x0
      double  y0
      double  x1
      double  y1


#  int pl_flinerel ___P((double dx0, double dy0, double dx1, double dy1)); 
int
pl_flinerel(dx0,dy0,dx1,dy1)
      double  dx0
      double  dy0
      double  dx1
      double  dy1


#  int pl_flinewidth ___P((double size)); 
int
pl_flinewidth(size)
      double  size


#  int pl_fmarker ___P((double x, double y, int type, double size)); 
int
pl_fmarker(x,y,type,size)
      double  x
      double  y
      int  type
      double  size


#  int pl_fmarkerrel ___P((double dx, double dy, int type, double size)); 
int
pl_fmarkerrel(dx,dy,type,size)
      double  dx
      double  dy
      int  type
      double  size


#  int pl_fmove ___P((double x, double y)); 
int
pl_fmove(x,y)
      double  x
      double  y


#  int pl_fmoverel ___P((double dx, double dy)); 
int
pl_fmoverel(dx,dy)
      double  dx
      double  dy


#  int pl_fpoint ___P((double x, double y)); 
int
pl_fpoint(x,y)
      double  x
      double  y


#  int pl_fpointrel ___P((double dx, double dy)); 
int
pl_fpointrel(dx,dy)
      double  dx
      double  dy


#  int pl_fspace ___P((double x0, double y0, double x1, double y1)); 
int
pl_fspace(x0,y0,x1,y1)
      double  x0
      double  y0
      double  x1
      double  y1


#  int pl_fspace2 ___P((double x0, double y0, double x1, double y1, double x2, double y2)); 
int
pl_fspace2(x0,y0,x1,y1,x2,y2)
      double  x0
      double  y0
      double  x1
      double  y1
      double  x2
      double  y2


#  int pl_fconcat ___P((double m0, double m1, double m2, double m3, double m4, double m5)); 
int
pl_fconcat(m0,m1,m2,m3,m4,m5)
      double  m0
      double  m1
      double  m2
      double  m3
      double  m4
      double  m5


#  int pl_fmiterlimit ___P((double limit)); 
int
pl_fmiterlimit(limit)
      double  limit


#  int pl_frotate ___P((double theta)); 
int
pl_frotate(theta)
      double  theta


#  int pl_fscale ___P((double x, double y)); 
int
pl_fscale(x,y)
      double  x
      double  y


#  int pl_ftranslate ___P((double x, double y)); 
int
pl_ftranslate(x,y)
      double  x
      double  y


#  int pl_newpl ___P((___const char *type, FILE *infile, FILE *outfile, FILE *errfile)); 
int
pl_newpl(type,infile,outfile,errfile)
      char  *type
      FILE  *infile
      FILE  *outfile
      FILE  *errfile


#  int pl_selectpl ___P((int handle)); 
int
pl_selectpl(handle)
      int  handle


#  int pl_deletepl ___P((int handle)); 
int
pl_deletepl(handle)
      int  handle

#  int pl_parampl ___P((___const char *parameter, void *value)); 
int
pl_parampl(parameter,value)
      char  *parameter
      char  *value


