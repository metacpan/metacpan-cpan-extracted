#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/******************************************************************************
 *          Copyright (c) 2006 Toutatis Internet Publishing Software 
 *          All rights reserved.                 http://toutatis.com
 *
 * This library is free software; you can redistribute it and/or modify it 
 * under the same terms as Perl itself. See the "Artistic License" in the Perl 
 * source code distribution for licensing terms.
 *
 ******************************************************************************
 * Author: Joost Diepenmaat / Zeekat Softwareontwikkeling - joost@zeekat.nl
 ******************************************************************************
 * WKB parsing code taken from mapserver, which has the following copyright
 * notification:
 ******************************************************************************
 * Copyright (c) 1996-2005 Regents of the University of Minnesota.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in 
 * all copies of this Software or works derived from this Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ******************************************************************************
 */



#if !defined(_WIN32)
#include <netinet/in.h>
#endif
#include <sys/types.h>


#define MAX_POINTS_PER_LINE 20000

#ifndef LITTLE_ENDIAN
#define LITTLE_ENDIAN 1
#endif
#ifndef BIG_ENDIAN
#define BIG_ENDIAN 2
#endif

#ifndef WKBTYPE_GEOMETRY
#define WKBTYPE_GEOMETRY 0
#define WKBTYPE_POINT 1
#define WKBTYPE_LINESTRING 2
#define WKBTYPE_POLYGON 3
#define WKBTYPE_MULTIPOINT 4
#define WKBTYPE_MULTILINESTRING 5
#define WKBTYPE_MULTIPOLYGON 6
#define WKBTYPE_GEOMETRYCOLLECTION 7
#endif

#include <gd.h>

static int gBYTE_ORDER = 0;

static gdPoint points[MAX_POINTS_PER_LINE];

void Geo__GD__Image_end_memcpy(char order, void* dest, void* src, int num)
{
  u_int16_t* shorts=NULL;
  u_int32_t* longs;
  int order_test = 1;
  
  if (gBYTE_ORDER ==0) {
    if( ((char *) &order_test)[0] == 1 ) gBYTE_ORDER = LITTLE_ENDIAN;
    else gBYTE_ORDER = BIG_ENDIAN;
  }
  
  if (
      (gBYTE_ORDER == LITTLE_ENDIAN && order == 1) ||
      (gBYTE_ORDER == BIG_ENDIAN && order == 0) 		/* no change required */
      ){
  } else if ((gBYTE_ORDER == LITTLE_ENDIAN && order == 0)){	/* we're little endian but data is big endian */
  } else if ((gBYTE_ORDER == BIG_ENDIAN && order == 1)){	/* we're big endian but data is little endian */
    
    switch (num){
    case 2:
      shorts = (u_int16_t*) shorts;
      *shorts = htons(*shorts);
      break;
    case 4:			
      longs = (u_int32_t*) src;
      *longs = htonl(*longs);
      break;
    case 8:			
      longs = (u_int32_t*) src;
      *longs = htonl(*longs);
      longs ++;
      *longs = htonl(*longs);
      break;
    }
    
  }
  memcpy(dest, src, num);
}

int Geo__GD__Image_add_point(gdImagePtr image, char *wkb, int color, double offsetx, double offsety, double ratiox, double ratioy)
{
  char byteorder = 0;
  float x;
  float y;

  byteorder = wkb[0];
  
  Geo__GD__Image_end_memcpy(byteorder,  &x , &wkb[5  ], 8);
  Geo__GD__Image_end_memcpy(byteorder,  &y , &wkb[5+8], 8);
  gdImageSetPixel(image, (int) ( ratiox * ( x - offsetx ) ), (int) ( ratioy * ( y - offsety ) ), color);
  return 0;
}


int Geo__GD__Image_add_linestring(gdImagePtr image, char *wkb, int color, double offsetx, double offsety, double ratiox, double ratioy)
{
  int	u;
  char byteorder = 0;
  byteorder = wkb[0];
  int numpoints;
  int x1,y1,x2,y2;

  Geo__GD__Image_end_memcpy(byteorder, &numpoints, &wkb[5],4); /* num points */

  if (numpoints > MAX_POINTS_PER_LINE) croak("Too many points. Increase MAX_POINTS_PER_LINE");
  if (numpoints < 2) {
    croak("Can't handle a linestring with less than 2 points");
  }
  else if (numpoints == 2) {
    Geo__GD__Image_end_memcpy(byteorder,  &x1 , &wkb[9], 8);
    Geo__GD__Image_end_memcpy(byteorder,  &y1 , &wkb[17], 8);    
    Geo__GD__Image_end_memcpy(byteorder,  &x2 , &wkb[25], 8);
    Geo__GD__Image_end_memcpy(byteorder,  &y2 , &wkb[33], 8);    
    gdImageLine(image, 
		(int) ( ratiox * ( x1 - offsetx ) ), 
		(int) ( ratioy * ( y1 - offsety ) ),
		(int) ( ratiox * ( x2 - offsetx ) ), 
		(int) ( ratioy * ( y2 - offsety ) ),
		color);
  }
  else {

    for(u=0;u<numpoints ; u++)
      {
	Geo__GD__Image_end_memcpy(byteorder, &x1, &wkb[9 + (16 * u)], 8);
	Geo__GD__Image_end_memcpy(byteorder, &y1, &wkb[9 + (16 * u)+8], 8);
	points[u].x = (int) ( ratiox * ( x1 - offsetx ) );
	points[u].y = (int) ( ratioy * ( y1 - offsety ) );
      }
    gdImageOpenPolygon(image, points, numpoints, color);
  }
  return 9 + (16 * numpoints);
}

int Geo__GD__Image_add_multilinestring( gdImagePtr image, char *wkb,int color, double offsetx, double offsety, double ratiox, double ratioy)
{
  int offset =0;
  int u;
  int nstrings;
  char byteorder = 0;

  byteorder = wkb[0];
  
  Geo__GD__Image_end_memcpy(byteorder, &nstrings, &wkb[offset+5],4); /* num linstrings */
  for(u=0;u<nstrings ; u++)
    {
      offset += Geo__GD__Image_add_linestring( image, &wkb[offset+9], color, offsetx, offsety, ratiox, ratioy );
    }
  return offset;
}

int Geo__GD__Image_add_polygon(gdImagePtr image, char *wkb, int color, double offsetx, double offsety, double ratiox, double ratioy) {
  int offset =0,pt_offset;
  int u,v;
  int type,nrings,npoints;
  char byteorder = 0;
  double x,y;
  
  byteorder = wkb[0];

  Geo__GD__Image_end_memcpy(byteorder, &nrings, &wkb[offset+5],4); /* num rings */
  /* add a line for each polygon ring */
  pt_offset = 0;
  offset += 9; /* now points at 1st linear ring */
  for (u=0;u<nrings;u++)	/* for each ring, make a line */
    {
      Geo__GD__Image_end_memcpy(byteorder, &npoints, &wkb[offset],4); /* num points */

      if (npoints > MAX_POINTS_PER_LINE) croak("Too many points. Increase MAX_POINTS_PER_LINE");

      for(v=0;v<npoints;v++)
	{
	  Geo__GD__Image_end_memcpy(byteorder,  &x , &wkb[offset+4 + (16 * v)], 8);
	  Geo__GD__Image_end_memcpy(byteorder,  &y , &wkb[offset+4 + (16 * v)+8], 8);
	  points[v].x = (int) ( ratiox * ( x - offsetx ) );
	  points[v].y = (int) ( ratioy * ( y - offsety ) );
	  /*	  printf("%f x %f -> %d x %d ( %f  x %f )\n",x,y,points[v].x, points[v].y,  ratiox * ( x - offsetx ), ratioy * ( y - offsety )); */
	}
      /* make offset point to next linear ring */
      gdImageFilledPolygon(image, points, npoints, color);
      offset += 4+ (16)*npoints;
    }
  return offset;
}


int Geo__GD__Image_add_multipolygon(gdImagePtr image, char *wkb, int color, double offsetx, double offsety, double ratiox, double ratioy)  {
  int offset =0;
  int w;
  char byteorder = 0;
  int npolygons;
  byteorder = wkb[0];
  
  Geo__GD__Image_end_memcpy(byteorder, &npolygons, &wkb[offset+5],4); /* num polygons */
  offset+=9;
  for (w=0; w< npolygons; w++) {
    offset += Geo__GD__Image_add_polygon(image, &wkb[offset], color, offsetx, offsety, ratiox, ratioy );
  }
  return offset;
}



/* add a WKB blob to an image */

int	Geo__GD__Image_draw_wkb(gdImagePtr image, char *wkb, int color, double offsetx, double offsety, double ratiox, double ratioy)
{
  
  int offset =0;
  int	type,t,ngeoms;
  char byteorder = 0;
  
  byteorder = wkb[0];
  
  Geo__GD__Image_end_memcpy(byteorder,  &type, &wkb[1], 4);
  switch(type) {
  case WKBTYPE_POLYGON:
    return Geo__GD__Image_add_polygon(image, wkb, color, offsetx, offsety, ratiox, ratioy);
    break;
  case WKBTYPE_MULTIPOLYGON:
    return Geo__GD__Image_add_multipolygon(image, wkb, color, offsetx, offsety, ratiox, ratioy);
    break;
  case WKBTYPE_GEOMETRYCOLLECTION:
    Geo__GD__Image_end_memcpy(byteorder,  &ngeoms, &wkb[5], 4);
    offset = 9;  /* were the first geometry is */
    for (t=0; t<ngeoms; t++)
      {
	offset+= Geo__GD__Image_draw_wkb( image, &wkb[offset], color, offsetx, offsety, ratiox, ratioy);
      }
    return offset;
    break;
  case WKBTYPE_LINESTRING:
    return Geo__GD__Image_add_linestring(image, wkb, color, offsetx, offsety, ratiox, ratioy);
    break;
  case WKBTYPE_MULTILINESTRING:
    return Geo__GD__Image_add_multilinestring(image, wkb, color, offsetx, offsety, ratiox, ratioy);
    break;
  case WKBTYPE_POINT:
    return Geo__GD__Image_add_point(image, wkb, color, offsetx, offsety, ratiox, ratioy);
    break;
  }
  croak("Unhandled WKB (sub)type %d",type);
}


MODULE = Geo::GD::Image		PACKAGE = Geo::GD::Image	PREFIX= Geo__GD__Image_	

int
Geo__GD__Image_draw_wkb( image, wkb, color, offsetx, offsety, ratiox, ratioy)
  gdImagePtr image
  char * wkb
  int color
  double offsetx
  double offsety
  double ratiox
  double ratioy

  
int 
Geo__GD__Image_alpha( image, c )
  gdImagePtr image
  int c
  CODE:
    RETVAL = gdImageAlpha(image,c);
  OUTPUT:
    RETVAL
