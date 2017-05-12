// C code for Image::Filter::Blur
// Simple Black & White Blur
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr blur_bw (gdImagePtr imageptr)
{ gdImagePtr imblur;
  int dimx = 0;
  int dimy = 0;
  int w = 0;
  int h = 0;
  int index = 0;
  int newcolor = 0;
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);
  imblur = gdImageCreateTrueColor(dimx,dimy);
  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { newcolor = (int) (
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h-1))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h+1))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h-1))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h+1))+
  
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h-1))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h+1)) )/9; 

      newcolor = newcolor > 255 ? 255 : (newcolor < 0 ? 0 : newcolor);
      index = gdImageColorExact(imblur,newcolor,newcolor,newcolor);
      if (index == -1) { index = gdImageColorAllocate(imblur,newcolor,newcolor,newcolor); }
      gdImageSetPixel(imblur,w,h,index);
    }
  }

  return imblur;
}

gdImagePtr blur_color (gdImagePtr imageptr)
{ gdImagePtr imblur;
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
  imblur = gdImageCreateTrueColor(dimx,dimy);
  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { newrcolor = (int) (
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h-1))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h+1))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h-1))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h+1))+
  
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h-1))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h))+
      gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h+1)) )/9; 

      newgcolor = (int) (
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w-1,h-1))+
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w-1,h))+
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w-1,h+1))+
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h-1))+
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h))+
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w,h+1))+
  
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w+1,h-1))+
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w+1,h))+
      gdImageGreen(imageptr,gdImageGetPixel(imageptr,w+1,h+1)) )/9; 

      newbcolor = (int) (
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w-1,h-1))+
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w-1,h))+
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w-1,h+1))+
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h-1))+
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h))+
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w,h+1))+
  
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w+1,h-1))+
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w+1,h))+
      gdImageBlue(imageptr,gdImageGetPixel(imageptr,w+1,h+1)) )/9; 

      newrcolor = newrcolor > 255 ? 255 : (newrcolor < 0 ? 0 : newrcolor);
      newgcolor = newgcolor > 255 ? 255 : (newgcolor < 0 ? 0 : newgcolor);
      newbcolor = newbcolor > 255 ? 255 : (newbcolor < 0 ? 0 : newbcolor);
      index = gdImageColorExact(imblur,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(imblur,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(imblur,w,h,index);
    }
  }

  return imblur;
}

gdImagePtr blur (gdImagePtr imageptr, int type)
{ gdImagePtr imblur;
  if (type == 1)
  { imblur = blur_bw(imageptr); }
  else { imblur = blur_color(imageptr); }
  return imblur;
}
