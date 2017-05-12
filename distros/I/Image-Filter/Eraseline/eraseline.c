// C code for Image::Filter::Eraseline
// Simple Line Erasing
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

// Does not "erase" half lines, when thickness > remaining lines

gdImagePtr eraseline (gdImagePtr imageptr, int thickness, int orientation, int newr, int newg, int newb)
{ gdImagePtr imerase;
  int dimx = 0;
  int dimy = 0;
  int w = 0;
  int h = 0;
  int newcolor = 0;
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);
  imerase = gdImageCreateTrueColor(dimx,dimy);
  gdImageCopy(imerase,imageptr,0,0,0,0,dimx,dimy);
  newcolor = gdImageColorAllocate(imerase, newr, newg, newb);
  if (newcolor == -1) { newcolor = gdImageColorClosest(imerase,newr,newg,newb); }
  if (orientation == 0)
  { for (h = thickness; h < dimy-thickness ; h += thickness*2)
    { gdImageFilledRectangle(imerase,0,h,dimx,h+thickness-1,newcolor);  
    }
  }
  else 
  { for (w = thickness; w < dimx-thickness ; w += thickness*2)
    { gdImageFilledRectangle(imerase,w,0,w+thickness-1,dimy,newcolor);  
    }
  }
  return imerase;
}
