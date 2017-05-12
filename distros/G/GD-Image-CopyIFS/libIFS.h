#ifndef lib_IFS_H
#define lib_IFS_H

#include <gd.h>
#include <stdio.h>
#include <stdlib.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef dNOOP
#  define NOOP (void)0
#  define dNOOP extern int Perl___notused PERL_UNUSED_DECL
#endif

#ifndef dTHR
#  define dTHR          dNOOP
#endif

#ifndef dTHX
#  define dTHX          dNOOP
#  define dTHXa(x)      dNOOP
#  define dTHXoa(x)     dNOOP
#endif

#ifndef pTHX
#    define pTHX	void
#    define pTHX_
#    define aTHX
#    define aTHX_
#endif

typedef struct {
  double x, y;
  int rgb[4];
} ifs;

void gdImageCopyIFS (gdImagePtr dstImg, gdImagePtr srcImg, 
                     int dstX, int dstY, int srcX, int srcY,
                     int dstW, int dstH, int srcW, int srcH,
                     double min_factor, double max_factor);

void generate_ifs (gdImagePtr srcImg, ifs **z,
                   int srcX, int srcY, int dstX, int dstY, 
                   int srcW, int srcH, int dstW, int dstH);

void generate_ifs_image (gdImagePtr dstImg, ifs **z, int **seen,
                         int srcX, int srcY, int dstX, int dstY,
                         int srcW, int srcH, int dstW, int dstH,
			 int dstXend, int dstYend,
			 double min_factor, double max_factor);

void fill_in_blanks (gdImagePtr dstImg, int **seen, 
                     int dstX, int dstY, int dstXend, int dstYend);

void rgb_linear (double newx, double newy, ifs **z, 
                 int m, int n, double x, double y, double xm1, double ym1, 
                 int *rgb);

int nearest (int **seen, int i, int j, 
             int xstart, int ystart, int width, int height);

int **imatrix(long nrl, long nrh, long ncl, long nch);
ifs **ifsmatrix(long nrl, long nrh, long ncl, long nch);
void free_imatrix(int **m, long nrl, long nrh, long ncl, long nch);
void free_ifsmatrix(ifs **m, long nrl, long nrh, long ncl, long nch);

#endif
