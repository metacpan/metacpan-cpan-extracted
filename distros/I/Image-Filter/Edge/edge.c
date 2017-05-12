// C code for Image::Filter::Edge
// (c) 2002 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include <gd.h>

gdImagePtr edge (gdImagePtr imageptr)
{ gdImagePtr imedge;
  int dimx = 0;
  int dimy = 0;
  int w = 0;
  int h = 0;
  int index = 0;
  int factor = 50;
  int newcolor = 0;
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);
  imedge = gdImageCreateTrueColor(dimx,dimy);

  for (w = 0; w < dimx ; w++)
  { for (h = 0; h < dimy ; h++)
    { newcolor = (int) (  
	-gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h-1))
	-gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h))
	-gdImageRed(imageptr,gdImageGetPixel(imageptr,w-1,h+1))

	-gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h-1))
	-gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h))
	-gdImageRed(imageptr,gdImageGetPixel(imageptr,w+1,h+1))

	-gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h-1))
	+(8*gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h)))
	-gdImageRed(imageptr,gdImageGetPixel(imageptr,w,h+1)));
   
       newcolor = newcolor > 255 ? 255 : (newcolor < 0 ? 0 : newcolor);
       index = gdImageColorExact(imedge,newcolor,newcolor,newcolor);
       if (index == -1) { index = gdImageColorAllocate(imedge,newcolor,newcolor,newcolor); }
       gdImageSetPixel(imedge,w,h,index);
    }
  }

  return imedge;
}
