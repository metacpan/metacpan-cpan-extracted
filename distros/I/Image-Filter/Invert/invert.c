// C code for Image::Filter::Invert
// Simple Invert
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr invertize (gdImagePtr imageptr)
// Yes, this is cheating... I'll swap in in the package
{ gdImagePtr iminvert;
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
  iminvert = gdImageCreateTrueColor(dimx,dimy);
  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { newrcolor = 255-gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h));
      newgcolor = 255-gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h));
      newbcolor = 255-gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h));
      index = gdImageColorExact(iminvert,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(iminvert,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(iminvert,w,h,index);
    }
  }
  return iminvert;
}
