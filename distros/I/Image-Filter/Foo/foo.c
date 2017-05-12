// C code for Image::Filter::Foo
// An example filter module
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr foo (gdImagePtr imageptr)
{ gdImagePtr imfoo;
  int dimx = 0;
  int dimy = 0;
  int w = 0;
  int h = 0;
  int index = 0;
  int newcolor = 0;
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);
  imfoo = gdImageCreateTrueColor(dimx,dimy);
  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { //Manipulate your pixels here :)
      // newcolor = gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h));
      // newcolor = newcolor > 255 ? 255 : (newcolor < 0 ? 0 : newcolor);
      // index = gdImageColorExact(imfoo,newcolor,newcolor,newcolor);
      // if (index == -1) { index = gdImageColorAllocate(imfoo,newcolor,newcolor,newcolor); }
      // gdImageSetPixel(imfoo,w,h,index);
    }
  }
  return imfoo;
}
