// C code for Image::Filter::Ripple
// Rippling
// (c) 2003 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"

gdImagePtr ripple (gdImagePtr imageptr, int numwaves)
{ gdImagePtr imripple;
  int newrcolor = 0;
  int newgcolor = 0;
  int newbcolor = 0;
  int rcolor = 0;
  int gcolor = 0;
  int bcolor = 0;
  int x = 0;
  int y = 0;
  int h = 0;
  int w = 0;
  int dimx = 0;
  int dimy = 0;
  int index = 0;
  int a = 0;
  double wp = 0;
  double hp = 0;
  double w1 = 0.5;
  double w2 = 0.5;
  double angle = 0;
  double dx = 0;
  double dy = 0;
  double r = 0;
  double z = 0;
  double sin_array[360];
  double cos_array[360];
  int waves = numwaves;
  double maxradius = 0;
  double frequency = 0;
  double amplitude = 0;
  double attenuation = 0;
  dimx = gdImageSX(imageptr);
  dimy = gdImageSY(imageptr);

  imripple = gdImageCreateTrueColor(dimx,dimy);

  wp = dimx * 0.5;
  hp = dimy * 0.5;

  for(a = 0;  a < 360; a++) 
  { sin_array[a] = sin((M_PI * a) / 180.0);
	cos_array[a] = cos((M_PI * a) / 180.0);
  }
	
  maxradius = sqrt(wp * wp + hp * hp);
  frequency = 360.0 * waves / maxradius;
  amplitude = maxradius / 10.0;

  for (h = 0; h < dimy+1; h++) 
  { for (w = 0; w < dimx+1; w++) 
    { dx = w - wp;
	  dy = h - hp;
	  angle = 180.0 * (atan2(dx, dy) / M_PI);
	  if(angle < 0) 
	  { angle += 360.0; }
	  r = sqrt(dx * dx + dy * dy);
      z = amplitude / pow(r, attenuation) * sin_array[((int)(frequency * r)) % 360];
  	a = ((int)(angle)) % 360;
	  x = (int)(w + z * cos_array[a]);
	  y = (int)(h + z * sin_array[a]);
			
      rcolor = gdImageRed(imageptr,gdImageGetPixel(imageptr,x,y));
      gcolor = gdImageGreen(imageptr,gdImageGetPixel(imageptr,x,y));
      bcolor = gdImageBlue(imageptr,gdImageGetPixel(imageptr,x,y));

      newrcolor = rcolor * w1 + rcolor * w2;
      newgcolor = gcolor * w1 + gcolor * w2;
      newbcolor = bcolor * w1 + bcolor * w2;
            
      newrcolor = newrcolor > 255 ? 255 : (newrcolor < 0 ? 0 : newrcolor);
      newgcolor = newgcolor > 255 ? 255 : (newgcolor < 0 ? 0 : newgcolor);
      newbcolor = newbcolor > 255 ? 255 : (newbcolor < 0 ? 0 : newbcolor);
      index = gdImageColorExact(imripple,newrcolor,newgcolor,newbcolor);
      if (index == -1) { index = gdImageColorAllocate(imripple,newrcolor,newgcolor,newbcolor); }
      gdImageSetPixel(imripple,w,h,index);
	}
  }
  return imripple;
}

