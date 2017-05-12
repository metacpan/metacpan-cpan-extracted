// C code for Image::Filter::Greyscale
// Simple weighted average greyscale routine
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr greyscale (gdImagePtr imageptr)
{ gdImagePtr imgrey;
  int dimx = 0;
  int dimy = 0;
  int w = 0;
  int h = 0;
  int index = 0;
  int newcolor = 0;
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);
  imgrey = gdImageCreateTrueColor(dimx,dimy);
  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { newcolor = (int)
      (3 * gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h)) +
       2 * gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h)) +
       4 * gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h)) ) / 9;
      index = gdImageColorExact(imgrey,newcolor,newcolor,newcolor);
      if (index == -1) { index = gdImageColorAllocate(imgrey,newcolor,newcolor,newcolor); }
      gdImageSetPixel(imgrey,w,h,index);
    }
  }
  return imgrey;
}
