// C code for Image::Filter::Posterize
// Simple Black & White Posterize
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr posterize (gdImagePtr imageptr)
{ gdImagePtr impost;
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
  impost = gdImageCreateTrueColor(dimx,dimy);
  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { newrcolor = gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h));
      newgcolor = gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h));
      newbcolor = gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h));
      newrcolor = newrcolor < 64 ? 0 : 
                ( newrcolor > 64 && newrcolor < 128 ? 85 : 
	          ( newrcolor > 128 && newrcolor < 192 ? 170 : 255 ) );
      newgcolor = newgcolor < 64 ? 0 : 
                ( newgcolor > 64 && newgcolor < 128 ? 85 : 
	          ( newgcolor > 128 && newgcolor < 192 ? 170 : 255 ) );

      newbcolor = newbcolor < 64 ? 0 : 
                ( newbcolor > 64 && newbcolor < 128 ? 85 : 
	          ( newbcolor > 128 && newbcolor < 192 ? 170 : 255 ) );

      index = gdImageColorExact(impost,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(impost,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(impost,w,h,index);
    }
  }
  return impost;
}
