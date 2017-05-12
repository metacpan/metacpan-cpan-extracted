/* Copyright 2010 Kevin Ryde

   This file is part of Image-Base-GD.

   Image-Base-GD is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Image-Base-GD is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License along
   with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.  */

#include <stdio.h>
#include <stdlib.h>
#include <gd.h>

int
main (void)
{
  gdImagePtr im;
  int black, white;
  FILE *fp;

  im = gdImageCreate (20, 10);

  black = gdImageColorAllocate(im, 0, 0, 0);
  white = gdImageColorAllocate(im, 255, 255, 255);

  gdImageFilledRectangle(im, 0,0, 19,9, black);
  gdImageRectangle(im, 5,5, 15,5, white);

  fp = fopen("/tmp/x.png", "wb");
  if (fp == NULL) abort();
  gdImagePng(im, fp);
  if (ferror(fp)) abort();
  if (fclose(fp) != 0) abort();

  system ("convert  -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");
  exit(0);
}

