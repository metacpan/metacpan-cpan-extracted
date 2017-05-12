// C code for Image::Filter::Floyd
// Floyd-Steinberg Dithering
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr floyd (gdImagePtr imageptr, int limit)
{ gdImagePtr imfloyd;
  int dimx = 0;
  int dimy = 0;
  int w = 0;
  int h = 0;
  int pixel = 0;
  int newpixel = 0;
  int index = 0;
  int diff = 0;
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);
  imfloyd = gdImageCreateTrueColor(dimx,dimy);
  for (w = 0; w < dimx-2 ; w++)
  { for (h = 1; h < dimy-2 ; h++)
    { pixel = (gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h)) > limit ? 255 : 0);
      diff = gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h))-pixel;
      index = gdImageColorExact(imfloyd,pixel,pixel,pixel);
      if (index == -1) 
      { index = gdImageColorAllocate(imageptr,pixel,pixel,pixel); }
        gdImageSetPixel(imfloyd,w,h,index);
 
        newpixel = (int) (gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h)) + (7/16 * diff));
        newpixel = newpixel > 255 ? 255 : (newpixel < 0 ? 0 : newpixel);
        index = gdImageColorExact(imageptr,newpixel,newpixel,newpixel);
        if (index == -1) 
        { index = gdImageColorAllocate(imageptr,newpixel,newpixel,newpixel); }
        gdImageSetPixel(imageptr,w+1,h,index);

        newpixel = (int) (gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h+1)) + (1/16 * diff));
        newpixel = newpixel > 255 ? 255 : (newpixel < 0 ? 0 : newpixel);
        index = gdImageColorExact(imageptr,newpixel,newpixel,newpixel);
        if (index == -1) 
        { index = gdImageColorAllocate(imageptr,newpixel,newpixel,newpixel); }
        gdImageSetPixel(imageptr,w+1,h+1,index);

        newpixel = (int) (gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h+1)) + (3/16 * diff));
        newpixel = newpixel > 255 ? 255 : (newpixel < 0 ? 0 : newpixel);
        index = gdImageColorExact(imageptr,newpixel,newpixel,newpixel);
        if (index == -1) 
        { index = gdImageColorAllocate(imageptr,newpixel,newpixel,newpixel); }
        gdImageSetPixel(imageptr,w-1,h+1,index);

        newpixel = (int) (gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h+1)) + (5/16 * diff));
        newpixel = newpixel > 255 ? 255 : (newpixel < 0 ? 0 : newpixel);
        index = gdImageColorExact(imageptr,newpixel,newpixel,newpixel);
        if (index == -1) 
        { index = gdImageColorAllocate(imageptr,newpixel,newpixel,newpixel); }
        gdImageSetPixel(imageptr,w,h+1,index);
    }
 }
 return imfloyd;
}
