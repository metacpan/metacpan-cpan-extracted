#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "gd.h"

MODULE = Image::Filter		PACKAGE = Image::Filter		

PROTOTYPES: DISABLE

gdImagePtr newFromJpeg(filename)
char*  filename

gdImagePtr newFromPng(filename)
char*  filename

gdImagePtr newFromGd(filename)
char*  filename

gdImagePtr newFromGd2(filename)
char*  filename

void Png(imageptr, filename)
gdImagePtr imageptr
char* filename

void Gd(imageptr, filename)
gdImagePtr imageptr
char* filename

void Gd2(imageptr, filename)
gdImagePtr imageptr
char* filename

void Jpeg(imageptr, filename, quality=100)
gdImagePtr imageptr
char* filename
int quality
INIT:
    if (quality > 100)
    { fprintf (stderr,"Quality cannot exceed 100. Truncating...\n");
      quality = 100;
    }

void Destroy(imageptr)
gdImagePtr imageptr
