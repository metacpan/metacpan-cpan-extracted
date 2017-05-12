// C code for Image::Filter::Twirl
// Rotate your image in a funny way ;-)
// (c) 2003 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr twirl (gdImagePtr imageptr)
{ gdImagePtr imtwirl;
  int rcolor = 0;
  int gcolor = 0;
  int bcolor = 0;
  int newrcolor = 0;
  int newgcolor = 0;
  int newbcolor = 0;
  int x = 0;
  int y = 0;
  int h = 0;
  int w = 0;
  int dimx = 0;
  int dimy = 0;
  int index = 0;
  double wp = 0;
  double hp = 0;
  double a = 0;
  double dx = 0;
  double dy = 0;
  double d = 0;
  double dist = 0;
  double angle = 0;
  
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);

  wp = dimx * 0.5;
  hp = dimy * 0.5;

  imtwirl = gdImageCreateTrueColor(dimx,dimy);
  
  a = atan2(-1.0, wp - 1.0);
  if(a < 0.0) a += 2.0 * M_PI;
  dx = dimx / a;
  d  = sqrt(hp * hp + wp * wp);
  dy = dimy / d;

  for (h = 0; h < dimy+1; h++) 
  { for (w = 0; w < dimx+1; w++) 
    { x = (w - wp);
      y = (h - hp);
      dist  = sqrt(x * x + y * y);
      angle = atan2(y, x);
      if(angle < 0) 
      { angle += 2.0 * M_PI; }
      newrcolor = gdImageRed(imageptr,gdImageGetPixel(imageptr,(int)(dimx - dx * angle),(int)(dy * dist)));
      newgcolor = gdImageGreen(imageptr,gdImageGetPixel(imageptr,(int)(dimx - dx * angle),(int)(dy * dist)));
      newbcolor = gdImageBlue(imageptr,gdImageGetPixel(imageptr,(int)(dimx - dx * angle),(int)(dy * dist)));
      newrcolor = newrcolor > 255 ? 255 : (newrcolor < 0 ? 0 : newrcolor);
      newgcolor = newgcolor > 255 ? 255 : (newgcolor < 0 ? 0 : newgcolor);
      newbcolor = newbcolor > 255 ? 255 : (newbcolor < 0 ? 0 : newbcolor);
      index = gdImageColorExact(imtwirl,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(imtwirl,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(imtwirl,w,h,index);
	}
  }
  return imtwirl;
}

