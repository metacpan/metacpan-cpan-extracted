// C code for Image::Filter::Solarize
// Solarize
// (c) 2003 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "gd.h"

gdImagePtr solarize (gdImagePtr imageptr, int seed)
{ gdImagePtr imsolarize;
  int newrcolor = 0;
  int newgcolor = 0;
  int newbcolor = 0;
  int rcolor = 0;
  int gcolor = 0;
  int bcolor = 0;
  int w = 0;
  int h = 0;
  int dimx = 0;
  int dimy = 0;
  int index = 0;
  int z = seed;
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);

  imsolarize = gdImageCreateTrueColor(dimx,dimy);
  for (h = 0; h < dimy+1; h++) 
  { for (w = 0; w < dimx+1; w++) 
    { rcolor = gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h));
      gcolor = gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h));  
      bcolor = gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h));
      newrcolor = rcolor > z*w / 2*w ? rcolor : z-rcolor;
      newgcolor = gcolor > z*w / 2*w ? gcolor : z-gcolor;
      newbcolor = bcolor > z*w / 2*w ? bcolor : z-bcolor;      
      newrcolor = newrcolor > 255 ? 255 : (newrcolor < 0 ? 0 : newrcolor);
      newgcolor = newgcolor > 255 ? 255 : (newgcolor < 0 ? 0 : newgcolor);
      newbcolor = newbcolor > 255 ? 255 : (newbcolor < 0 ? 0 : newbcolor);
      index = gdImageColorExact(imsolarize,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(imsolarize,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(imsolarize,w,h,index);
    }
  }
  return imsolarize;
}
