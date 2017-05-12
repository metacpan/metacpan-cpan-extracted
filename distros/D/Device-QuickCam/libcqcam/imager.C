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

// simple CQC and graphical wizardry:
//   * auto-exposure
//   * despeckling
//   * 32->24 bpp conversions
//   * Floyd dithering
//
// dithering contributed by:
//   Andre Jsemanowicz <andre@andrix.biophysics.mcw.edu>

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>      /* get bzero() for Solaris */
#include <unistd.h>
#include <math.h>

#ifdef JPEG
// extern "C" is here because jpeglib v6a is not safe (by default) for
// c++. Careless on the part of the authors...
extern "C" {
#include <jpeglib.h>
}
#endif

// original credits for write_ppm() to the qcam authors,
// modified by Patrick
void write_ppm(FILE *output, unsigned char *buf, int width, int height) {
  long i;

  fprintf(output, "P6\n%d %d 255\n", width, height);

  for (i = 0; i < width * height * 3; i++) {
    fputc(buf[i], output);
  }
}

#ifdef JPEG
// originally by Shawn Stepper <stepper@vip.stanford.edu>
// modified to fit cqcam better by Patrick
void write_jpeg(FILE *output, unsigned char *buf, int width, int height,
  int quality) {
  struct jpeg_compress_struct cinfo;
  struct jpeg_error_mgr jerr;
  JSAMPROW row_pointer[1];     // pointer to JSAMPLE row(s)
  int row_stride;              // physical row width in image buffer

  cinfo.err = jpeg_std_error(&jerr);
  jpeg_create_compress(&cinfo);

  jpeg_stdio_dest(&cinfo, output);
  cinfo.image_width = width;          // image width and height, in pixels
  cinfo.image_height = height;
  cinfo.input_components = 3;         // # of color components per pixel
  cinfo.in_color_space = JCS_RGB;     // colorspace of input image

  jpeg_set_defaults(&cinfo);
  jpeg_set_quality(&cinfo, quality, TRUE);  // limit to baseline-JPEG values
  jpeg_start_compress(&cinfo, TRUE);
  row_stride = cinfo.input_components*width;  // JSAMPLE units per row
  while (cinfo.next_scanline < cinfo.image_height) {
    /* jpeg_write_scanlines expects an array of pointers to scanlines.
     * Here the array is only one element long, but you could pass
     * more than one scanline at a time if that's more convenient.
     */
    row_pointer[0] = &buf[cinfo.next_scanline * row_stride];
    jpeg_write_scanlines(&cinfo, row_pointer, 1);  
  }
  jpeg_finish_compress(&cinfo);
  jpeg_destroy_compress(&cinfo);
}
#endif

#define BRIGHTNESS_TARGET 90
#define BRIGHTNESS_ERROR 4

int get_brightness_adj(unsigned char *image, long size, int &brightness) {
  long avg;
  register long tot = 0;
#ifdef NO_ASM
  register int i;
  register unsigned char *p = image;
  for (i=0;i<size*3;i++)
    tot += *p++;
#else
  __asm__ (
  /* ecx and esi have to get saved because gcc 2.95 no longer provides a
   * clean way to indicate that input registers will be clobbered. */
    "push %%ecx\n"
    "push %%esi\n"
    "cld\n"
    "xor %%edx,%%edx\n"
    "xor %%ebx,%%ebx\n"
    "1: lodsl\n"
    "mov %%al,%%bl\n"
    "shr $8,%%eax\n"
    "add %%ebx,%%edx\n"
    "mov %%al,%%bl\n"
    "shr $8,%%eax\n"
    "add %%ebx,%%edx\n"
    "mov %%al,%%bl\n"
    "shr $8,%%eax\n"
    "add %%ebx,%%edx\n"
    "add %%eax,%%edx\n"
    "loop 1b\n"
    "pop %%esi\n"
    "pop %%ecx"
    :"=d"(tot)
    :"c"(size*3/4), "S"((long)image)
    :"ax", "bx", "cc");
#endif
  avg = tot/(size*3);
  brightness = (BRIGHTNESS_TARGET - avg)/3;
  return (avg >= BRIGHTNESS_TARGET - BRIGHTNESS_ERROR
		&& avg <= BRIGHTNESS_TARGET + BRIGHTNESS_ERROR);
}

#ifndef min
#define min(x, y) (((x) > (y))  ?  (y)  :  (x))
#endif
#ifndef max
#define max(x, y) (((x) > (y))  ?  (x)  :  (y))
#endif

void get_rgb_adj(unsigned char *image, long size, int &red, int &green,
  int &blue) {
  register long rtot = 0, gtot = 0, btot = 0;
#ifdef NO_ASM
  register int i;
  register unsigned char *p = image;
  for (i=0; i<size; i++) {
    rtot += *p++;
    gtot += *p++;
    btot += *p++;
  }
#else
  __asm__ (
  /* ecx and esi have to get saved because gcc 2.95 no longer provides a
   * clean way to indicate that input registers will be clobbered. */
    "push %%ecx\n"
    "push %%esi\n"
    "cld\n"
    "xor %%eax,%%eax\n"
    "xor %%ebx,%%ebx\n"
    "xor %%edx,%%edx\n"
    "xor %%edi,%%edi\n"
    "1: lodsb\n"
    "add %%eax,%%ebx\n"
    "lodsb\n"
    "add %%eax,%%edx\n"
    "lodsb\n"
    "add %%eax,%%edi\n"
    "loop 1b\n"
    "pop %%esi\n"
    "pop %%ecx"
    :"=b"(rtot),"=d"(gtot),"=D"(btot)
    :"c"(size), "S"((long)image)
    :"ax", "cc");
#endif
  if (rtot/size < 64) rtot = size*64;
  if (gtot/size < 64) gtot = size*64;
  if (btot/size < 64) btot = size*64;
  red = min(16384 / (rtot/size), 255);
  green = min(16384 / (gtot/size), 255);
  blue = min(16384 / (btot/size), 255);
}

void do_rgb_adj(unsigned char *image, long size, int red, int green,
  int blue) {
#ifdef NO_ASM
  register long i;
  register unsigned char *p = image;
  for (i=0; i<size; i++) {  
    /* note: don't use *p++ here, because min() is a macro that evaluates
     * one of its arguments (whichever is less) twice */
    *p = min(*p * red   >> 7, 255); p++;
    *p = min(*p * green >> 7, 255); p++;
    *p = min(*p * blue  >> 7, 255); p++;
  }  
#else
  __asm__ (
  /* ecx, edi, and esi have to get saved because gcc 2.95 no longer provides a
   * clean way to indicate that input registers will be clobbered. */
    "push %%ecx\n"
    "push %%esi\n"
    "push %%edi\n"
    "cld\n"
    "1: lodsb\n"
    "mul %%bl\n"
    "shr $7,%%eax\n"
    "cmp $255,%%ax\n"
    "jbe 2f\n"
    "mov $255,%%al\n"
    "2: stosb\n"
    "lodsb\n"
    "mul %%bh\n"
    "shr $7,%%eax\n"
    "cmp $255,%%ax\n"
    "jbe 3f\n"
    "mov $255,%%al\n"
    "3: stosb\n"
    "lodsb\n"
    "mul %%dl\n"
    "shr $7,%%eax\n"
    "cmp $255,%%ax\n"
    "jbe 4f\n"
    "mov $255,%%al\n"
    "4: stosb\n"
    "loop 1b\n"
    "pop %%edi\n"
    "pop %%esi\n"
    "pop %%ecx"
    :
    :"b"(red|(green<<8)),"c"(size),"d"(blue),"S"((long)image),"D"((long)image)
    :"ax", "cc");
#endif
}

void allocate_rgb_palette(int size, int pal[][3], int rgb[][3]) {
  int i, j, k = 0, m;
  float f0 = 1.0/(size - 1);
  float a;

  int *fix = new int[size];

  for (i=0; i<size; i++) {
    a = i * f0;
    k = (int)(255 * a + 0.5);
    fix[i] = max(0, min(k, 255));
  }

  m = 0;
  for (i=0; i<size; i++)
    for (j=0; j<size; j++)
      for (k=0; k<size; k++) {
        pal[m][0] = fix[i];
        pal[m][1] = fix[j];
        pal[m++][2] = fix[k];
      }
  m = 0;
  for (i=0; i<256; i++) {
    rgb[i][0] = m * size * size;
    rgb[i][1] = m * size;
    rgb[i][2] = m;
    if (i > fix[m] + k)
      k = (fix[m+1] - fix[m++])/2;
  }
  delete[] fix;
}

unsigned char *rgb_2_pal(unsigned char *image, int width, int height,
  int size, int pal[][3], int rgb[][3]) {
  int i;
  int m = 0;
  unsigned char *ret = new unsigned char[width * height];
  for (i=0; i<height; i++) {
    for (int j=0; j<width; j++) {
      int k = rgb[image[m]][0] + rgb[image[m+1]][1] + rgb[image[m+2]][2];
      ret[i * width + j] = max(0, min(k, size*size*size-1));

      int temprgb[3];
      temprgb[0] = image[m] - pal[k][0];
      temprgb[1] = image[m+1] - pal[k][1];
      temprgb[2] = image[m+2] - pal[k][2];

      if (j < width - 1)
        for (int n=0; n<3; n++)
          image[m + 3 + n] =
            max(0, min(255, image[m + 3 + n] + ((temprgb[n] * 7) >> 4)));

      if (i < height - 1) {
        int n;
        if (j > 0)
          for (n=0; n<3; n++)
            image[m + 3*width - 3 + n] =
              max(0, min(255, image[m + 3*width - 3 + n] +
              ((temprgb[n] * 3) >> 4)));
        for (n=0; n<3; n++)
          image[m + 3*width + n] = max(0, min(255, image[m + 3*width + n] +
            ((temprgb[n] * 5) >> 4)));
        if (j < height - 1)
          for (n=0; n<3; n++)
            image[m + 3*width + 3 + n] =
              max(0, min(255, image[m + 3*width + 3 + n] + (temprgb[n] >> 4)));
      } // if
      m += 3;
    } // for j
  } // for i
  delete[] image;
  return ret;
}

unsigned char *despeckle32(unsigned char *image, int width, int height);

unsigned char *raw32_to_24(unsigned char *buf, int width, int height,
  int nospecks) {

// input buffer is of the form B,G1,G2,R ... (see p.34 and p.45)

  unsigned char *retbuf;
  int i, j;
  if (nospecks)
    buf = despeckle32(buf, width, height/4);
  retbuf = new unsigned char[width * height * 3];

// there's a band on the right and the bottom where the overlapped-
// pixels algorithm fails to provide pixels.  (fix me?)  Blank it out with 
// bzero() so that it will be black.
  bzero(retbuf, width*height*3);
  unsigned char *temp[4];
  for (i=0; i<width; i+=2)
    for (j=0; j<height; j+=2) {

// the **temp array points to four non-overlapping input pixels
// 0-4 are upper-left, upper-right, lower-left, and lower-right, respectively
// for details, see the appendix of the ColorQC specs from Connectix
      temp[0] = &buf[i*2 + j*width];
      temp[1] = &buf[i*2+4 + j*width];
      temp[2] = &buf[i*2 + (j+2)*width];
      temp[3] = &buf[i*2+4 + (j+2)*width];

      // upper-left output pixel
      retbuf[3*i + 3*j*width] = temp[0][3];                // BG // red
      retbuf[2 + 3*i + 3*j*width] = temp[0][0];            // GR // blue
      retbuf[1 + 3*i + 3*j*width] =
        (temp[0][1] + temp[0][2])/2;                             // green

      // upper-right output pixel
      retbuf[3*(i+1) + 3*j*width] = temp[0][3];            // GB // red
      retbuf[2 + 3*(i+1) + 3*j*width] = temp[1][0];        // RG // blue
      retbuf[1 + 3*(i+1) + 3*j*width] =
        (temp[0][2] + temp[1][1])/2;                             // green

      // lower-left output pixel
      retbuf[3*i + 3*(j+1)*width] = temp[0][3];            // GR // red
      retbuf[2 + 3*i + 3*(j+1)*width] = temp[2][0];        // BG // blue
      retbuf[1 + 3*i + 3*(j+1)*width] =
        (temp[0][1] + temp[2][2])/2;                             // green

      // lower-right output pixel
      retbuf[3*(i+1) + 3*(j+1)*width] = temp[0][3];        // RG // red
      retbuf[2 + 3*(i+1) + 3*(j+1)*width] = temp[3][0];    // GB // blue
      retbuf[1 + 3*(i+1) + 3*(j+1)*width] =
        (temp[1][1] + temp[2][2])/2;                             // green
    }
  delete[] buf;

  return retbuf;
}

// the light-check threshold.  Higher numbers remove more lights but blur the
// image more.  30 is good for indoor lighting.
#define NO_LIGHTS 30

// macros to make the code a little more readable, p=previous, n=next
#define RED image[i*3]
#define GREEN image[i*3+1]
#define BLUE image[i*3+2]
#define pRED image[i*3-3]
#define pGREEN image[i*3-2]
#define pBLUE image[i*3-1] 
#define nRED image[i*3+3]
#define nGREEN image[i*3+4] 
#define nBLUE image[i*3+5]

unsigned char *despeckle(unsigned char *image, int width, int height) {
  unsigned char *newimage = new unsigned char[width*height*3];
  if (newimage == NULL) {
    fprintf(stderr, "malloc() failed while allocating %d bytes\n",
      width*height*3);
    exit(1);
  }
  long i;
  for (i=0; i<width*height; i++) {
    if (i % width == 0 || i % width == width - 1)
      memcpy(&newimage[i*3], &image[i*3], 3);
    else {
      if (RED - (GREEN+BLUE)/2 >
        NO_LIGHTS + ((pRED - (pGREEN+pBLUE)/2) +
        (nRED - (nGREEN+nBLUE)/2)))
        newimage[i*3] = (pRED+nRED)/2;
        else newimage[i*3] = RED;
      if (GREEN - (RED+BLUE)/2 >
        NO_LIGHTS + ((pGREEN - (pRED+pBLUE)/2) +
        (nGREEN - (nRED+nBLUE)/2)))
        newimage[i*3+1] = (pGREEN+nGREEN)/2;
        else newimage[i*3+1] = GREEN;
      if (BLUE - (GREEN+RED)/2 >
        NO_LIGHTS + ((pBLUE - (pGREEN+pRED)/2) +
        (nBLUE - (nGREEN+nRED)/2)))
        newimage[i*3+2] = (pBLUE+nBLUE)/2;
        else newimage[i*3+2] = BLUE;
    }  // if width
  }    // for
  delete[] image;
  return newimage;
}

// more macros (undef the old ones first) to make the code more readable
#undef RED
#undef GREEN
#undef BLUE
#undef pRED
#undef pGREEN
#undef pBLUE
#undef nRED
#undef nGREEN
#undef nBLUE

#define RED image[i*4]
#define GREENa image[i*4+1]
#define GREENb image[i*4+2]
#define BLUE image[i*4+3]
#define pRED image[i*4-4]
#define pGREENa image[i*4-3]
#define pGREENb image[i*4-2]
#define pBLUE image[i*4-1]
#define nRED image[i*4+4]
#define nGREENa image[i*4+5]
#define nGREENb image[i*4+6]
#define nBLUE image[i*4+7]

unsigned char *despeckle32(unsigned char *image, int width, int height) {
  unsigned char *newimage = new unsigned char[width*height*4];
  if (newimage == NULL) {
    fprintf(stderr, "malloc() failed while allocating %d bytes\n",
      width*height*4);
    exit(1);
  }
  long i;
  for (i=0; i<width*height; i++) {
    if (i % width == 0 || i % width == width - 1)
      memcpy(&newimage[i*4], &image[i*4], 4);
    else {
      if (RED - ((GREENa+GREENb)/2+BLUE)/2 >
        NO_LIGHTS + ((pRED - ((pGREENa+pGREENb)/2+pBLUE)/2) +
        (nRED - ((nGREENa+nGREENb)/2+nBLUE)/2)))
        newimage[i*4] = (pRED+nRED)/2;
        else newimage[i*4] = RED;
      if (GREENa - (RED+BLUE)/2 >
        NO_LIGHTS + ((pGREENa - (pRED+pBLUE)/2) +
        (nGREENa - (nRED+nBLUE)/2)))
        newimage[i*4+1] = (pGREENa+nGREENa)/2;
        else newimage[i*4+1] = GREENa;
      if (GREENb - (RED+BLUE)/2 >
        NO_LIGHTS + ((pGREENb - (pRED+pBLUE)/2) +
        (nGREENb - (nRED+nBLUE)/2)))
        newimage[i*4+2] = (pGREENb+nGREENb)/2;
        else newimage[i*4+2] = GREENb;
      if (BLUE - ((GREENa+GREENb)/2+RED)/2 >
        NO_LIGHTS + ((pBLUE - ((pGREENa+pGREENb)/2+pRED)/2) +
        (nBLUE - ((nGREENa+nGREENb)/2+nRED)/2)))
        newimage[i*4+3] = (pBLUE+nBLUE)/2;
        else newimage[i*4+3] = BLUE;
    }  // if width
  }    // for
  delete[] image;
  return newimage;
}
