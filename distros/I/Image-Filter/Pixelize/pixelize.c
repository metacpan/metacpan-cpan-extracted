// C code for Image::Filter::Pixelize
// Simple 4 block pixelize
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr pixelize (gdImagePtr imageptr)
{ gdImagePtr impixel;
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
  impixel = gdImageCreateTrueColor(dimx,dimy);
  for (w = 0; w < dimx-1 ; w += 2)
  { for (h = 0; h < dimy-1 ; h += 2)
    { newrcolor = gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h));
      newgcolor = gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h));
      newbcolor = gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h));
      index = gdImageColorExact(impixel,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(impixel,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(impixel,w,h,index);
      gdImageSetPixel(impixel,w+1,h,index);
      gdImageSetPixel(impixel,w,h+1,index);
      gdImageSetPixel(impixel,w+1,h+1,index);
    }
  }
  return impixel;
}
