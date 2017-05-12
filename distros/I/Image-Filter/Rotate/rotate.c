// C code for Image::Filter::Rotate
// Simple CCW Rotate
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr rotate (gdImagePtr imageptr)
{ gdImagePtr imrotate;
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
  imrotate = gdImageCreateTrueColor(dimy,dimx);
  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { newrcolor = gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h));
      newgcolor = gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h));
      newbcolor = gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h));
      index = gdImageColorExact(imrotate,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(imrotate,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(imrotate,h,w,index);
    }
  }
  return imrotate;
}
