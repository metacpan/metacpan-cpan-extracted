#include "libIFS.h"

/* 
************************************************************
copy an image from srcImg to dstImg via an IFS algorithm.
The source starts at (srcX, srcY), of size (srcW, srcH),
and is copied to the destination, starting at (dstX, dstY),
of size (dstW, dstH).

min_factor, between 0 and 1, determines the minimum fraction of 
the destination points to be colored by the IFS algorthm. The 
remainder simply use the nearest available pixel to determine 
the colour. Values very close to 1 will produce better looking 
images, but will take longer.

max_factor, greater than 1, determines the maximum number
of iterations that the IFS algorithm uses. A value of 1
will have this iteration number equal to the number of
pixels in the destination; increasing this value will
produce better looking images, but at the expense of speed.
Reasonable values are around 5.
**********************************************************
*/

void gdImageCopyIFS (gdImagePtr dstImg, gdImagePtr srcImg, 
                     int dstX, int dstY, int srcX, int srcY,
                     int dstW, int dstH, int srcW, int srcH,
                     double min_factor, double max_factor) {
  
  ifs **z;
  int **seen, i, j, dstXend, dstYend;

  if (min_factor < 0 || min_factor > 1)
    Perl_croak(aTHX_ "min_factor must be between 0 and 1");
  if (max_factor < 1)
    Perl_croak(aTHX_ "max_factor must be larger than 1");

  dstXend = dstX + dstW;
  dstYend = dstY + dstH;
  
  /* allocate some arrays */
  z = ifsmatrix(srcX, srcX + srcW, srcY, srcY + srcH);
  seen = imatrix(dstX, dstX + dstW, dstY, dstY + dstH);
  
  /* initialize some arrays */
  for (i=dstX; i<=dstXend; i++) {
    for (j=dstY; j<=dstYend; j++) {
      seen[i][j] = 0;
    }
  }
 
  generate_ifs(srcImg, z, srcX, srcY, dstX, dstY,
               srcW, srcH, dstW, dstH);
  
  generate_ifs_image(dstImg, z, seen, srcX, srcY, dstX, dstY,
                     srcW, srcH, dstW, dstH, dstXend, dstYend,
		     min_factor, max_factor);
  
  fill_in_blanks(dstImg, seen, dstX, dstY, dstXend, dstYend);
  
  free_ifsmatrix(z, srcX, srcX+srcW, srcY, srcY+srcH);
  free_imatrix(seen, dstX, dstX+dstW, dstY, dstY+dstH);
  
}

void generate_ifs (gdImagePtr srcImg, ifs **z,
                   int srcX, int srcY, int dstX, int dstY, 
                   int srcW, int srcH, int dstW, int dstH) {
  int srcXend, srcYend, i, j, index, srcIsTrue;
  double scaleX, scaleY;
  
  srcXend = srcX + srcW;
  srcYend = srcY + srcH;
  scaleX = (double) (dstW) / (double) (srcW);
  scaleY = (double) (dstH) / (double) (srcH);
  
  srcIsTrue = srcImg->trueColor;

  for (i=srcX; i<=srcXend; i++) {
    for (j=srcY; j<=srcYend; j++) {
      z[i][j].x = dstX + scaleX * (i-srcX);
      z[i][j].y = dstY + scaleY * (j-srcY);
      if (srcIsTrue) {
        index = gdImageGetTrueColorPixel(srcImg, i, j);
        z[i][j].rgb[0] = gdTrueColorGetRed(index);
        z[i][j].rgb[1] = gdTrueColorGetGreen(index);
        z[i][j].rgb[2] = gdTrueColorGetBlue(index);
        z[i][j].rgb[3] = gdTrueColorGetAlpha(index);
      }
      else {
        index = gdImageGetPixel(srcImg, i, j);
        z[i][j].rgb[0] = gdImageRed(srcImg, index);
        z[i][j].rgb[1] = gdImageGreen(srcImg, index);
        z[i][j].rgb[2] = gdImageBlue(srcImg, index);
        z[i][j].rgb[3] = gdImageAlpha(srcImg, index);
      }
    }
  }
}


void generate_ifs_image (gdImagePtr dstImg, ifs **z, int **seen,
                         int srcX, int srcY, int dstX, int dstY,
                         int srcW, int srcH, int dstW, int dstH,
			 int dstXend, int dstYend,
			 double min_factor, double max_factor) {

  int count = 0, hits = 0, max, min, m, n, im, in, rgb[4], index, 
    transparent, dstIsTrue;
  double oldx = 3.3, oldy = 4.7, newx, newy, x, y, xm1, ym1;

  transparent = gdImageGetTransparent(dstImg);
  dstIsTrue = dstImg->trueColor;
  
  max = (int) (max_factor * dstW * dstH);
  min = (int) (min_factor * dstW * dstH);
  
  for (count=0; count<max; count++) {
    m = 1 + srcX + (int) ((double) srcW * rand() / (RAND_MAX + 1.0) );
    n = 1 + srcY + (int) ((double) srcH * rand() / (RAND_MAX + 1.0) );
    x = z[m][n].x;
    y = z[m][n].y;
    xm1 = z[m-1][n].x;
    ym1 = z[m][n-1].y;
    newx = ( (oldx-dstX)*x + (dstXend-oldx)*xm1 ) / dstW;
    newy = ( (oldy-dstY)*y + (dstYend-oldy)*ym1 ) / dstH;
    im = (int) newx;
    in = (int) newy;
    if (seen[im][in] > 0) continue;
    rgb_linear(newx, newy, z, m, n, x, y, xm1, ym1, rgb);
    index = gdImageColorResolveAlpha(dstImg, rgb[0], rgb[1], rgb[2], rgb[3]);
    seen[im][in] = index;
    if (index == transparent || index <= 0) continue;
    if (hits++ > min) break;
    gdImageSetPixel(dstImg, im, in, index);
    oldy = newy;
    oldx = newx;
  }
}

void fill_in_blanks (gdImagePtr dstImg, int **seen, 
                     int dstX, int dstY, int dstXend, int dstYend) {

  int transparent, i, j, index;

  transparent = gdImageGetTransparent(dstImg);

  for (i=dstX; i<=dstXend; i++) {
    for (j=dstY; j<=dstYend; j++) {
      if (seen[i][j] > 0) continue;
      index = nearest(seen, i, j, dstX, dstY, dstXend, dstYend);
      if (index <= 0 || index == transparent) continue;
      gdImageSetPixel(dstImg, i, j, index);
    }
  }
}

void rgb_linear (double newx, double newy, ifs **z, 
                int m, int n, double x, double y, double xm1, double ym1, 
                int *rgb) {

  double denX, denY;
  int i;

  denX = x - xm1;
  denY = y - ym1;

  for (i=0; i<=3; i++) {
    rgb[i]=
      (int) ( ( (newx-xm1)*(newy-ym1)*z[m][n].rgb[i] -
                (newx-x)*(newy-ym1)*z[m-1][n].rgb[i] -
                (newx-xm1)*(newy-y)*z[m][n-1].rgb[i] +
                (newx-x)*(newy-y)*z[m-1][n-1].rgb[i]
                ) / denX / denY);
    if (rgb[i] < 0) rgb[i] = 0 ;
    if (rgb[i] > 255) rgb[i] = 255 ;
  }
}

int nearest (int **seen, int i, int j, 
             int dstX, int dstY, int dstXend, int dstYend) {
  int m, n;
  
  for (m=i-1; m<=i+1; m++) {
      if (m<dstX || m>dstXend) continue;
      for (n=j-1; n<=j+1; n++) {
	  if (n<dstY || n>dstYend || seen[m][n] == 0) continue;
	  return seen[m][n];
      }
  }
  return -1;
}

/* allocate an ifs matrix with subscript range m[nrl..nrh][ncl..nch] */
ifs **ifsmatrix(long nrl, long nrh, long ncl, long nch) {
    long i, nrow=nrh-nrl+1,ncol=nch-ncl+1;
    ifs **m;
    
    /* allocate pointers to rows */
    m=(ifs **) malloc((size_t)((nrow+1)*sizeof(ifs*)));
    if (!m) Perl_croak(aTHX_ "allocation failure 1 in matrix()");
    m += 1;
    m -= nrl;
    
    
    /* allocate rows and set pointers to them */
    m[nrl]=(ifs *) malloc((size_t)((nrow*ncol+1)*sizeof(ifs)));
    if (!m[nrl]) Perl_croak(aTHX_ "allocation failure 2 in matrix()");
    m[nrl] += 1;
    m[nrl] -= ncl;
    
    for(i=nrl+1;i<=nrh;i++) m[i]=m[i-1]+ncol;
    
    /* return pointer to array of pointers to rows */
    return m;
}

/* allocate a int matrix with subscript range m[nrl..nrh][ncl..nch] */
int **imatrix(long nrl, long nrh, long ncl, long nch) {
    long i, nrow=nrh-nrl+1,ncol=nch-ncl+1;
    int **m;
    
    /* allocate pointers to rows */
    m=(int **) malloc((size_t)((nrow+1)*sizeof(int*)));
    if (!m) Perl_croak(aTHX_ "allocation failure 1 in matrix()");
    m += 1;
    m -= nrl;
    
    
    /* allocate rows and set pointers to them */
    m[nrl]=(int *) malloc((size_t)((nrow*ncol+1)*sizeof(int)));
    if (!m[nrl]) Perl_croak(aTHX_ "allocation failure 2 in matrix()");
    m[nrl] += 1;
    m[nrl] -= ncl;
    
    for(i=nrl+1;i<=nrh;i++) m[i]=m[i-1]+ncol;
    
    /* return pointer to array of pointers to rows */
    return m;
}

/* free a ifs matrix allocated by ifsmatrix() */
void free_ifsmatrix(ifs **m, long nrl, long nrh, long ncl, long nch) {
    free((char*) (m[nrl]+ncl-1));
    free((char*) (m+nrl-1));
}

/* free an int matrix allocated by imatrix() */
void free_imatrix(int **m, long nrl, long nrh, long ncl, long nch) {
    free((char*) (m[nrl]+ncl-1));
    free((char*) (m+nrl-1));
}
