// C code for Image::Filter::Level
// Simple Black & White Level
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr level (gdImagePtr imageptr, int inputlevel)
{ gdImagePtr imlevel;
  int dimx = 0;
  int dimy = 0;
  int w = 0;
  int h = 0;
  int index = 0;
  int newrcolor = 0;
  int newgcolor = 0;
  int newbcolor = 0;
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);
  imlevel = gdImageCreateTrueColor(dimx,dimy);
  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { newrcolor = gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h))+inputlevel;
      newgcolor = gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h))+inputlevel;
      newbcolor = gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h))+inputlevel;
      newrcolor = newrcolor > 255 ? 255 : ( newrcolor < 0 ? 0 : newrcolor );
      newgcolor = newgcolor > 255 ? 255 : ( newgcolor < 0 ? 0 : newgcolor );
      newbcolor = newbcolor > 255 ? 255 : ( newbcolor < 0 ? 0 : newbcolor );
      index = gdImageColorExact(imlevel,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(imlevel,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(imlevel,w,h,index);
    }
  }

  return imlevel;
}
