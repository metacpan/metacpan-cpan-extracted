// C code for Image::Filter::Sharpen
// Simple Black & White Sharpen
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr sharpen (gdImagePtr imageptr)
{ gdImagePtr imsharp;
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
  imsharp = gdImageCreateTrueColor(dimx,dimy);
  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { newrcolor = (
      5*gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h))-
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h-1))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h+1))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h)) ); 

      newgcolor = (
      5*gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h))-
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w-1,h))+
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h-1))+
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h+1))+
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w+1,h)) ); 

      newbcolor = (
      5*gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h))-
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w-1,h))+
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h-1))+
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h+1))+
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w+1,h)) ); 

      newrcolor = newrcolor > 255 ? 255 : (newrcolor < 0 ? 0 : newrcolor);
      newgcolor = newgcolor > 255 ? 255 : (newgcolor < 0 ? 0 : newgcolor);
      newbcolor = newbcolor > 255 ? 255 : (newbcolor < 0 ? 0 : newbcolor);
      index = gdImageColorExact(imsharp,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(imsharp,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(imsharp,w,h,index);
    }
  }
  return imsharp;
}
