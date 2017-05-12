// C code for Image::Filter::Oilify
// Oilify
// (c) 2003 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "gd.h"

int compare_doubles (const void *a, const void *b);

gdImagePtr oilify (gdImagePtr imageptr, int seed)
{ gdImagePtr imoilify;
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
  int maskWidth  = seed;
  int maskHeight = seed;
  int half = 0;
  double rTable[100];
  double gTable[100];
  double bTable[100];

  maskWidth  = seed > 10 ? 10 : seed;
  maskHeight = seed > 10 ? 10 : seed;

  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);

  imoilify = gdImageCreateTrueColor(dimx,dimy);

  for (h = 0; h < dimy+1; h++) 
  { for (w = 0; w < dimx+1; w++) 
    { for (y = 0; y < maskHeight; y++) 
      { for (x = 0; x < maskWidth; x++) 
        { index = y * maskWidth + x;
          rTable[index] = (double) gdImageRed(imageptr,gdImageGetPixel(imageptr,w + x - maskWidth / 2, h + y - maskHeight / 2));
          gTable[index] = (double) gdImageGreen(imageptr,gdImageGetPixel(imageptr,w + x - maskWidth / 2, h + y - maskHeight / 2));
          bTable[index] = (double) gdImageBlue(imageptr,gdImageGetPixel(imageptr,w + x - maskWidth / 2, h + y - maskHeight / 2));
        }
      }
      qsort(rTable,seed*seed,sizeof(double),compare_doubles);
      qsort(gTable,seed*seed,sizeof(double),compare_doubles);
      qsort(bTable,seed*seed,sizeof(double),compare_doubles);
      
      half = (int) seed*seed/2;
      newrcolor = (int) ((rTable[half-1]+rTable[half])/2);
      newgcolor = (int) ((gTable[half-1]+gTable[half])/2);
      newbcolor = (int) ((bTable[half-1]+bTable[half])/2);

      newrcolor = newrcolor > 255 ? 255 : (newrcolor < 0 ? 0 : newrcolor);
      newgcolor = newgcolor > 255 ? 255 : (newgcolor < 0 ? 0 : newgcolor);
      newbcolor = newbcolor > 255 ? 255 : (newbcolor < 0 ? 0 : newbcolor);
      index = gdImageColorExact(imoilify,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(imoilify,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(imoilify,w,h,index);
    }
  }
  return imoilify;
}

int
compare_doubles (const void *a, const void *b)
{
  const double *da = (const double *) a;
  const double *db = (const double *) b;

  return (*da > *db) - (*da < *db);
}
