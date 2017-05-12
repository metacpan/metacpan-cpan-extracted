// C code for Image::Filter::Gaussian
// Gaussian Blur
// (c) 2003 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr gaussian (gdImagePtr imageptr)
{ gdImagePtr imgaussian;
  double maskData[49];
  double cx = 0;
  double cy = 0;
  double r = 0;
  double mult = 0;
  int rcolor = 0;
  int gcolor = 0;
  int bcolor = 0;
  int newrcolor = 0;
  int newgcolor = 0;
  int newbcolor = 0;
  int x = 0;
  int y = 0;
  int h = 0;
  int w = 0;
  int dimx = 0;
  int dimy = 0;
  int index = 0;
  int maskWidth  = 7;
  int maskHeight = 7;

  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);

  for(y = 0; y < maskHeight; y++) 
  { for(x = 0; x < maskWidth; x++) 
    { cx = (double)x - (double)(maskWidth - 1) / 2.0;
	  cy = (double)y - (double)(maskHeight - 1) / 2.0;
	  r = cx * cx + cy * cy;
	  mult += exp(-0.35 * r);
	}
  }

  mult = 1.0 / mult;

  imgaussian = gdImageCreateTrueColor(dimx,dimy);

  for(y = 0; y < maskHeight; y++) 
  { for(x = 0; x < maskWidth; x++) 
    { cx = (double)x - (double)(maskWidth - 1) / 2.0;
	  cy = (double)y - (double)(maskHeight - 1) / 2.0;
	  r = cx * cx + cy * cy;
	  maskData[y * maskWidth + x] = mult * exp(-0.35 * r);
	}
  }

  for (h = 0; h < dimy+1; h++) 
  { for (w = 0; w < dimx+1; w++) 
    { newrcolor = 0; newgcolor = 0; newbcolor = 0;
      for (y = 0; y < maskHeight; y++) 
	  { for (x = 0; x < maskWidth; x++) 
        { rcolor = gdImageRed(imageptr,gdImageGetPixel(imageptr,w + x - maskWidth / 2,h + y - maskHeight / 2));
          gcolor = gdImageGreen(imageptr,gdImageGetPixel(imageptr,w + x - maskWidth / 2,h + y - maskHeight / 2));
          bcolor = gdImageBlue(imageptr,gdImageGetPixel(imageptr,w + x - maskWidth / 2,h + y - maskHeight / 2));
          index = x + y * maskWidth;
          newrcolor += rcolor * maskData[index];
          newgcolor += gcolor * maskData[index];
          newbcolor += bcolor * maskData[index];
		}
	  }
      newrcolor = newrcolor > 255 ? 255 : (newrcolor < 0 ? 0 : newrcolor);
      newgcolor = newgcolor > 255 ? 255 : (newgcolor < 0 ? 0 : newgcolor);
      newbcolor = newbcolor > 255 ? 255 : (newbcolor < 0 ? 0 : newbcolor);
      index = gdImageColorExact(imgaussian,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(imgaussian,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(imgaussian,w,h,index);
	}
  }
  return imgaussian;
}

