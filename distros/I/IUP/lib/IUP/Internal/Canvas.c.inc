#ifdef HAVELIB_IUPCD

/* XXX-CHECKLATER include all headers for all supported drivers */
#include <cdcgm.h>       /* CD_CGM  */
#include <cddebug.h>     /* CD_DEBUG  */
#include <cddgn.h>       /* CD_DGN  */
#include <cddxf.h>       /* CD_DXF  */
#include <cdemf.h>       /* CD_EMF  */
#include <cdmf.h>        /* CD_METAFILE  */
#include <cdps.h>        /* CD_PS  */
#include <cdsvg.h>       /* CD_SVG  */
#include <cdwmf.h>       /* CD_WMF  */
#include <cdirgb.h>      /* CD_IMAGERGB CD_DBUFFERRGB  */

/* #include <cdclipbd.h>    / * CD_CLIPBOARD  */
/* #include <cdpicture.h>   / * CD_PICTURE  */
/* #include <cdprint.h>     / * CD_PRINTER  */
/* #include <cddbuf.h>      / * CD_DBUFFER  */
/* #include <cdimage.h>     / * CD_IMAGE  */
/* #include <cdpdf.h>       / * CD_PDF  */
/* #include <cdnative.h>    / * CD_NATIVEWINDOW  */
/* #include <cdiup.h>       / * CD_IUP  */
/* #include <cdgl.h>        / * CD_GL  */

#endif

/* convert 'SV' to 'Ihandle*' + do undef->NULL conversion */
#define mySV2IHN(a) (SvIOK(a) ? INT2PTR(Ihandle *, SvIVX(a)) : NULL)

cdCanvas* ref2cnv(SV* ref) {
  HV* h;
  SV** s;
  if ((h = (HV*)(SvRV(ref))) == NULL) return NULL;
  if ((s = hv_fetchs(h, "!int!cnvhandle", 0)) != NULL) return INT2PTR(cdCanvas*,SvIVX(*s));
  return NULL;
}

int AV2transmatrix(SV *A, double *buffer) {
  AV *array;
  int lastindex, i;  
  if ((!SvROK(A)) || (SvTYPE(SvRV(A)) != SVt_PVAV)) return 0;
  array = (AV *)SvRV(A);
  lastindex = av_len(array);
  if (lastindex<5) return 0;
  for(i=0; i<6; i++) buffer[i] = (double)SvNV(*av_fetch(array,i,0)); 
  return 1;
}

SV* transmatrix2AV(double *buffer) {
  int i;
  AV* array;
  array = (AV *)sv_2mortal((SV *)newAV()); /* new array */
  av_extend(array,6); /* not needed but faster */
  for(i=0; i<6; i++) av_push(array,newSVnv(buffer[i]));
  return newRV((SV*)array);
}

int AV2int(SV *A, int **data, int *n) {
  int * buffer;
  int lastindex, i;
  AV *array;

  if( (!SvROK(A)) || (SvTYPE(SvRV(A)) != SVt_PVAV) ) return 0;
  
  array = (AV *)SvRV(A);
  lastindex = av_len(array);
  
  buffer = malloc(sizeof(int)*(lastindex+1));
  if (!buffer) return 0;
  
  for(i=0; i<=lastindex; i++) buffer[i] = (int)SvIV(*av_fetch(array,i,0)); 
  *data = buffer;
  *n = lastindex+1;
  return 1;
}

int AV2long(SV *A, long **data, int *n) {
  long * buffer;
  int lastindex, i;
  AV *array;

  if( (!SvROK(A)) || (SvTYPE(SvRV(A)) != SVt_PVAV) ) return 0;
  
  array = (AV *)SvRV(A);
  lastindex = av_len(array);
  
  buffer = malloc(sizeof(long)*(lastindex+1));
  if (!buffer) return 0;
  
  for(i=0; i<=lastindex; i++) buffer[i] = (long)SvIV(*av_fetch(array,i,0)); 
  *data = buffer;
  *n = lastindex+1;
  return 1;
}

SV* long2AV(long *data, int n) {
  int i;
  AV *array;
  array = (AV *)sv_2mortal((SV *)newAV());
  av_extend(array,n); /* not needed but faster */
  for(i=0; i<n; i++) av_push(array,newSViv(data[i]));
  return newRV((SV*)array);  
}

int AV2bitmap(SV *A1, unsigned char **r, unsigned char **g, unsigned char **b, unsigned char **a, int *w, int *h) {
  unsigned char *buffer_r, *buffer_g, *buffer_b, *buffer_a;
  int lastindex1, lastindex2, i, j, error;
  AV *array1, *array2;
  SV *A2;
  int n, width, height;

  /* warn("XXX-DEBUG: r=%p g=%p b=%p a=%p\n",r,g,b,a); */
  if (!r || !g || !b) return 0;
  n = a ? 4 : 3;

  /* warn("XXX-DEBUG: AV2bitmap n=%d\n",n); */
  if( (!SvROK(A1)) || (SvTYPE(SvRV(A1)) != SVt_PVAV) ) return 0;
  array1 = (AV *)SvRV(A1);
  lastindex1 = av_len(array1);
  
  A2 = (SV*)(*av_fetch(array1,0,0));
  if( (!SvROK(A2)) || (SvTYPE(SvRV(A2)) != SVt_PVAV) ) return 0;
  array2 = (AV *)SvRV(A2);
  lastindex2 = av_len(array2);
  
  /* warn("XXX-DEBUG: li1=%d li2=%d", lastindex1, lastindex2); */
  if ((lastindex2+1)%n != 0) return 0;
  error=0;
  width = (lastindex2+1)/n;
  height = (lastindex1+1);
  buffer_r = malloc( sizeof(unsigned char) * width * height * n );
  buffer_g = buffer_r + width * height;
  buffer_b = buffer_g + width * height;
  buffer_a = (n==4) ? buffer_b + width * height : NULL;
  if (!buffer_r) error=1;
  
  /* warn("XXX-DEBUG: before for\n"); */
  for(i=0; (i<height && !error); i++) {
    A2 = (SV*)(*av_fetch(array1,i,0));
    array2 = (AV *)SvRV(A2);
    if (lastindex2 != av_len(array2)) {
      error=1;
    }
    else {
      for(j=0; j<width; j++) {
        buffer_r[i*width+j] = (unsigned char)SvUV(*av_fetch(array2,j*n,0));
        buffer_g[i*width+j] = (unsigned char)SvUV(*av_fetch(array2,j*n+1,0));
        buffer_b[i*width+j] = (unsigned char)SvUV(*av_fetch(array2,j*n+2,0));
        if(n==4) buffer_a[i*width+j] = (unsigned char)SvUV(*av_fetch(array2,j*n+3,0));
      }
    }
  }
  /* warn("XXX-DEBUG: after for\n"); */
  if (error) {
    if (buffer_r) free(buffer_r);
    if (buffer_g) free(buffer_g);
    if (buffer_b) free(buffer_b);
    if (buffer_a) free(buffer_a);
    return 0;
  }
  if(r) *r = buffer_r;
  if(g) *g = buffer_g;
  if(b) *b = buffer_b;
  if(a) *a = buffer_a;
  *h = height;
  *w = width;

  return 1;
}

SV* Bitmap2AV(unsigned char *r, unsigned char *g, unsigned char *b, unsigned char *a, unsigned char *m, int w, int h) {
  int i,j;
  AV *array1, *array2;

  int n = 0;
  if (r) n++;
  if (g) n++;
  if (b) n++;
  if (a) n++;
  if (m) n++;
  
  /* warn("XXX-DEBUG: Bitmap2AV n=%d r=%p g=%p b=%p a=%p m=%p w=%d h=%d\n", n,r,g,b,a,m,w,h); */
  array1 = (AV *)sv_2mortal((SV *)newAV());
  av_extend(array1,h); /* not needed but faster */  
  for(i=0; i<h; i++) {
    array2 = (AV *)sv_2mortal((SV *)newAV()); /* new array */
    av_extend(array2,w*n);
    for(j=0; j<w; j++) {
      if (r) av_push(array2,newSViv(r[i*w+j]));
      if (g) av_push(array2,newSViv(g[i*w+j]));
      if (b) av_push(array2,newSViv(b[i*w+j]));
      if (a) av_push(array2,newSViv(a[i*w+j]));
      if (m) av_push(array2,newSViv(m[i*w+j]));
    }
    av_push(array1,newRV((SV*)array2));
  }
  return newRV((SV*)array1);
}

SV* long2D2AV(long *data, int w, int h) {
  int i,j;
  AV *array1, *array2;
  array1 = (AV *)sv_2mortal((SV *)newAV());
  av_extend(array1,h); /* not needed but faster */
  for(i=0; i<h; i++) {
    array2 = (AV *)sv_2mortal((SV *)newAV()); /* new array */
    av_extend(array2,w); /* not needed but faster */
    for(j=0; j<w; j++) av_push(array2,newSViv(data[i*w+j]));
    av_push(array1,newRV((SV*)array2));
  }
  return newRV((SV*)array1);
}

SV* uchar2D2AV(unsigned char *data, int w, int h) {
  int i,j;
  AV *array1, *array2;
  array1 = (AV *)sv_2mortal((SV *)newAV());
  av_extend(array1,h); /* not needed but faster */
  for(i=0; i<h; i++) {
    array2 = (AV *)sv_2mortal((SV *)newAV()); /* new array */
    av_extend(array2,w); /* not needed but faster */
    for(j=0; j<w; j++) av_push(array2,newSVuv(data[i*w+j]));
    av_push(array1,newRV((SV*)array2));
  }
  return newRV((SV*)array1);  
}

int AV2long2D(SV *A1, long **data, int *w, int *h) {
  long * buffer;
  int lastindex1, lastindex2, i, j, error;
  AV *array1, *array2;
  SV *A2;
  
  if( (!SvROK(A1)) || (SvTYPE(SvRV(A1)) != SVt_PVAV) ) return 0;
  array1 = (AV *)SvRV(A1);
  lastindex1 = av_len(array1);
  
  A2 = (SV*)(*av_fetch(array1,0,0));
  if( (!SvROK(A2)) || (SvTYPE(SvRV(A2)) != SVt_PVAV) ) return 0;
  array2 = (AV *)SvRV(A2);
  lastindex2 = av_len(array2);
  
  buffer = malloc( sizeof(long) * (lastindex2+1) * (lastindex1+1) );
  if (!buffer) return 0;
  
  for(error=0, i=0; (i<=lastindex1 && !error); i++) {
    A2 = (SV*)(*av_fetch(array1,i,0));
    array2 = (AV *)SvRV(A2);
    if (lastindex2 != av_len(array2)) {
      error=1;
    }
    else {
      for(j=0; j<=lastindex2; j++) {
        buffer[i*(lastindex2+1)+j] = (long)SvIV(*av_fetch(array2,j,0));
      }
    }
  }
  if (error) {
    free(buffer);
    return 0;
  }
  *data = buffer;
  *h = lastindex1+1;
  *w = lastindex2+1;
  return 1;
}

int AV2uchar2D(SV *A1, unsigned char **data, int *w, int *h) {
  unsigned char * buffer;
  int lastindex1, lastindex2, i, j, error;
  AV *array1, *array2;
  SV *A2;
  
  if( (!SvROK(A1)) || (SvTYPE(SvRV(A1)) != SVt_PVAV) ) return 0;
  array1 = (AV *)SvRV(A1);
  lastindex1 = av_len(array1);
  
  A2 = (SV*)(*av_fetch(array1,0,0));
  if( (!SvROK(A2)) || (SvTYPE(SvRV(A2)) != SVt_PVAV) ) return 0;
  array2 = (AV *)SvRV(A2);
  lastindex2 = av_len(array2);
  
  buffer = malloc( sizeof(unsigned char) * (lastindex2+1) * (lastindex1+1) );
  if (!buffer) return 0;
  
  for(error=0, i=0; (i<=lastindex1 && !error); i++) {
    A2 = (SV*)(*av_fetch(array1,i,0));
    array2 = (AV *)SvRV(A2);
    if (lastindex2 != av_len(array2)) {
      error=1;
    }
    else {
      for(j=0; j<=lastindex2; j++) {
        buffer[i*(lastindex2+1)+j] = (unsigned char)SvUV(*av_fetch(array2,j,0));
      }
    }
  }
  if (error) {
    free(buffer);
    return 0;
  }
  *data = buffer;
  *h = lastindex1+1;
  *w = lastindex2+1;
  return 1;
}

typedef struct __IUPinternal_cdPalette {
  int n;
  long *palette;
} *IUP__Canvas__Palette;

typedef struct __IUPinternal_cdPattern {
  int w;
  int h;
  long *pattern;
} *IUP__Canvas__Pattern;

typedef struct __IUPinternal_cdStipple {
  int w;
  int h;
  unsigned char *fgbg;
} *IUP__Canvas__Stipple;

typedef cdImage *IUP__Canvas__InternalServerImage;
typedef cdState *IUP__Canvas__InternalState;
typedef cdContext *IUP__Canvas__InternalContext;
typedef cdBitmap *IUP__Canvas__Bitmap;

cdBitmap* BitmapFromFile(char * file_name) {
  imImage *image;
  cdBitmap* bitmap;
  int error;

  image = imFileImageLoadBitmap(file_name, 0, &error);
  /* warn("XXX-DEBUG: BitmapFromFile error=%d\n",error); */
  if (error) return NULL;
  if (!image) return NULL;    
  if (!imImageIsBitmap(image)) return NULL;
  if (image->color_space == IM_RGB)  {
    if (image->has_alpha) {
      /* warn("XXX-DEBUG: RGBA 0=%p 1=%p 2=%p 3=%p\n", image->data[0], image->data[1], image->data[2], image->data[3]); */
      bitmap = cdInitBitmap(image->width, image->height, CD_RGBA, image->data[0], image->data[1], image->data[2], image->data[3]);
    }
    else {
      /* warn("XXX-DEBUG: RGB\n"); */
      bitmap = cdInitBitmap(image->width, image->height, CD_RGB, image->data[0], image->data[1], image->data[2]);
    }
  }
  else {
    /* warn("XXX-DEBUG: MAP\n"); */
    bitmap = cdInitBitmap(image->width, image->height, CD_MAP, image->data[0], image->palette);
  }

  return(bitmap);
}
