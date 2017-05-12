// C code for Image::Filter::Channel
// Extract R,G or B channel from Image
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr channel (gdImagePtr imageptr, int chan)
{ gdImagePtr imchannel;
  int dimx = 0;
  int dimy = 0;
  int w = 0;
  int h = 0;
  int index = 0;
  float newccolor = 0.0;
  int newcolor = 0;
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);
  imchannel = gdImageCreate(dimx,dimy);
  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { if (chan == 1)
      { newccolor = gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h)); }
      if (chan == 2)
      { newccolor = gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h)); }
      if (chan != 1 && chan != 2)
      { newccolor = gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h)); }
      newcolor = (int) newccolor;
      newcolor = newcolor > 255 ? 255 : (newcolor < 0 ? 0 : newcolor);
      index = gdImageColorExact(imchannel,newcolor,newcolor,newcolor);
      if (index == -1) { index = gdImageColorAllocate(imchannel,newcolor,newcolor,newcolor); }
      gdImageSetPixel(imchannel,w,h,index);
    }
  }
  return imchannel;
}
