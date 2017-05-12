// C code for Image::Filter
// (c) 2003 - Hendrik Van Belleghem
// hendrik@quickndirty.org
// Released under the GPL

#include <math.h>
#include <stdio.h>
#include "gd.h"
#include <stdlib.h>

gdImagePtr newFromJpeg (char *filename)
{ FILE *in;
  gdImagePtr im;
  in = fopen(filename, "rb");
  if (in == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  im = gdImageCreateFromJpeg(in);
  fclose(in);
  return im;
}

gdImagePtr newFromPng (char *filename)
{ FILE *in;
  gdImagePtr im;
  in = fopen(filename, "rb");
  if (in == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  im = gdImageCreateFromPng(in);
  fclose(in);
  return im;
}

gdImagePtr newFromGd2 (char *filename)
{ FILE *in;
  gdImagePtr im;
  in = fopen(filename, "rb");
  if (in == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  im = gdImageCreateFromGd2(in);
  fclose(in);
  return im;
}

gdImagePtr newFromGd (char *filename)
{ FILE *in;
  gdImagePtr im;
  in = fopen(filename, "rb");
  if (in == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  im = gdImageCreateFromGd(in);
  fclose(in);
  return im;
}
/*
gdImagePtr newFromWmp (char *filename)
{ FILE *in;
  gdImagePtr im;
  in = fopen(filename, "rb");
  if (in == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  im = gdImageCreateFromWmp(in);
  fclose(in);
  return im;
}

gdImagePtr newFromXbm (char *filename)
{ FILE *in;
  gdImagePtr im;
  in = fopen(filename, "rb");
  if (in == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  im = gdImageCreateFromXbm(in);
  fclose(in);
  return im;
}
*/
void Png(gdImagePtr imageptr, char *filename)
{ FILE *out;
  out = fopen(filename, "wb");
  if (out == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  gdImagePng(imageptr, out);
  fclose(out);
}

void Jpeg(gdImagePtr imageptr, char *filename, int quality)
{ FILE *out;
  out = fopen(filename, "wb");
  if (out == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  gdImageJpeg(imageptr, out, quality);
  fclose(out);
}

void Gd(gdImagePtr imageptr, char *filename)
{ FILE *out;
  out = fopen(filename, "wb");
  if (out == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  gdImageGd(imageptr, out);
  fclose(out);
}

void Gd2(gdImagePtr imageptr, char *filename)
{ FILE *out;
  out = fopen(filename, "wb");
  if (out == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  gdImageGd2(imageptr, out, 0, GD2_FMT_COMPRESSED);
  fclose(out);
}
/*
void Xbm(gdImagePtr imageptr, char *filename)
{ FILE *out;
  out = fopen(filename, "wb");
  if (out == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  gdImageXbm(imageptr, out);
  fclose(out);
}

void Wmp(gdImagePtr imageptr, char *filename)
{ FILE *out;
  out = fopen(filename, "wb");
  if (out == NULL)
  { fprintf(stderr,"Cannot open %s\n",filename);
    exit(EXIT_FAILURE);
  }
  gdImageWmp(imageptr, out);
  fclose(out);
}
*/
void Destroy(gdImagePtr imageptr)
{ gdImageDestroy(imageptr); }
