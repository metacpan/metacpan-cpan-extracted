#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

double m_limit = 5;
double m_epsilon = 0.001;
unsigned int m_max_iter = 600;
unsigned int m_w = 640;
unsigned int m_h = 480;
double m_x1 = -2.2;
double m_x2 = +1;
double m_y1 = -1.1;
double m_y2 = +1.1;

/* C version (since using point() in XS code fails make test (but passes
   manual runs huh?) */

unsigned int _point(unsigned int x1, unsigned int y1)
  {
  double		za,zb,za1;
  double		za2,zb2;
  double		x,y;
  unsigned int		RETVAL;

  x = (x1 * (m_x2 - m_x1) / m_w) + m_x1;
  y = (y1 * (m_y2 - m_y1) / m_h) + m_y1;
  za = 0;
  zb = 0;
  za2 = 0;
  zb2 = 0;
  RETVAL = 0;
  while (RETVAL++ < m_max_iter)
    {
    za1 = za2 - zb2 + x;
    zb = 2 * za * zb + y;
    za = za1;
    za2 = za * za; zb2 = zb * zb; 
    if (za2 + zb2 > m_limit)
      {
      break;
      }
    }
  if (RETVAL >= m_max_iter)
    {
    RETVAL = 0;
    }
  return RETVAL;
  }


MODULE = Math::Fractal::Mandelbrot	PACKAGE = Math::Fractal::Mandelbrot
PROTOTYPES: ENABLE

##############################################################################
# point() - calculate fractal at this point
# input: X and Y   coordinates of the point

unsigned int
point(myclass, x1, y1)
	unsigned int x1
	unsigned int y1
  INIT:
    double		za,zb,za1;
    double		za2,zb2;
    double		x,y;

  CODE:
    x = (x1 * (m_x2 - m_x1) / m_w) + m_x1;
    y = (y1 * (m_y2 - m_y1) / m_h) + m_y1;
    za = 0;
    zb = 0;
    za2 = 0;
    zb2 = 0;
    RETVAL = 0;
    while (RETVAL++ < m_max_iter)
      {
      za1 = za2 - zb2 + x;
      zb = 2 * za * zb + y;
      za = za1;
      za2 = za * za; zb2 = zb * zb; 
      if (za2 + zb2 > m_limit)
        {
        break;
        }
      }
    if (RETVAL >= m_max_iter)
      {
      RETVAL = 0;
      }
  OUTPUT:
    RETVAL

##############################################################################
# hor_line() - calculate fractal at a horizontal stripe
# input: X and Y   coordinates of the start point
#        L 	   length of line

AV*
hor_line(myclass, x1, y1, l)
	unsigned int	x1
	unsigned int	y1
	unsigned int	l
  INIT:
    unsigned int	x, x2, i, last, iter, same;
    AV*			a2;

  CODE:
    a2 = (AV*)sv_2mortal((SV*)newAV());
    av_extend (a2, l + 1);
    x2 = x1 + l;
    i = 1; same = 0; last = _point (x1,y1);
    for (x = x1; x < x2; x++)
      {
      iter = _point (x,y1);
      av_push( a2, newSViv(iter) );
      if (iter == last) { same++; } else { break; }
      }
    for (;x < x2; x++)
      {
      iter = _point (x,y1);
      av_push( a2, newSViv(iter) );
      }
    av_push( a2, newSViv(same) );
    RETVAL = (AV*)a2;
  OUTPUT:
    RETVAL

##############################################################################
# ver_line() - calculate fractal at a vertical stripe
# input: X and Y   coordinates of the start point
#        L 	   length of line

AV*
ver_line(myclass, x1, y1, l)
	unsigned int	x1
	unsigned int	y1
	unsigned int	l

  INIT:
    unsigned int	y, y2, i, last, iter, same;
    AV*			a2;

  CODE:
    a2 = (AV*)sv_2mortal((SV*)newAV());
    av_extend (a2, l + 1);
    y2 = y1 + l;   
    i = 1; same = 0; last = _point (x1,y1);
    for (y = y1; y < y2; y++)
      {
      iter = _point (x1,y);
      av_push( a2, newSViv(iter) );
      if (iter == last) { same++; } else { break; }
      }
    for (;y < y2; y++)
      {
      iter = _point (x1,y);
      av_push( a2, newSViv(iter) );
      }
    av_push( a2, newSViv(same) );
    RETVAL = a2;
  OUTPUT:
    RETVAL


##############################################################################
# set_max_iter() - set maximum iterations
# input: new max_iter

unsigned int
set_max_iter(myclass, new_max_iter)
	unsigned int	new_max_iter
  CODE:
    m_max_iter = new_max_iter;
    if (new_max_iter == 0) { m_max_iter = 1; }		/* at least 1 */
    RETVAL = m_max_iter;
  OUTPUT:
    RETVAL


##############################################################################
# set_limit()
# input: new limit

double
set_limit(myclass, new_limit)
	double	new_limit
  CODE:
    m_limit = new_limit;
    RETVAL = m_limit;
  OUTPUT:
    RETVAL


##############################################################################
# set_epsilon()
# input: new limit

double
set_epsilon(myclass, new_e)
	double	new_e
  CODE:
    m_epsilon = new_e;
    RETVAL = m_epsilon;
  OUTPUT:
    RETVAL


##############################################################################
# set_bounds()
# input: x1,y1, x2,y2, w,h

void
set_bounds(myclass, nx1, ny1, nx2, ny2, nw, nh)
	double	nx1
	double	ny1
	double	nx2
	double	ny2
	unsigned int nw
	unsigned int nh
  CODE:
    m_x1 = nx1;
    m_y1 = ny1;
    m_x2 = nx2;
    m_y2 = ny2;
    m_w = nw;
    m_h = nh;

