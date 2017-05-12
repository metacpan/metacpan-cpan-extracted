/* libcqcam - shared Color Quickcam routines
 * Copyright (C) 1996-1998 by Patrick Reynolds
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

// prototypes for imager.C
//
// JPEG additions by: Shawn Stepper <stepper@vip.stanford.edu>

#ifndef IMAGER_H
#define IMAGER_H

#include "config.h"

void write_ppm(FILE *output, unsigned char *buf, int width, int height);

#ifdef JPEG
void write_jpeg(FILE *output, unsigned char *buf, int width, int height, 
  int quality);
#endif

int get_brightness_adj(unsigned char *image, long size, int &brightness);

void get_rgb_adj(unsigned char *image, long size, int &red, int &green,
  int &blue);

void do_rgb_adj(unsigned char *image, long size, int red, int green,
  int blue);

void allocate_rgb_palette(int size, int pal[][3], int rgb[][3]);

unsigned char *rgb_2_pal(unsigned char *image, int width, int height,
  int size, int pal[][3], int rgb[][3]);

unsigned char *raw32_to_24(unsigned char *buf, int width, int height,
#ifdef DESPECKLE
  int nospecks = 1);
#else
  int nospecks = 0);
#endif

unsigned char *despeckle(unsigned char *image, int width, int height);

#endif
