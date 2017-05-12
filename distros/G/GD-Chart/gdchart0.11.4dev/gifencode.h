/* GDCHART 0.10.0dev  GIFENCODE.H 2 Nov 2000 */
/* Copyright Bruce Verderaime 1998-2003 */

#ifndef _GIFENCODE_H
#define _GIFENCODE_H

void		gdImageGif( gdImagePtr im, FILE *out );
gdImagePtr	gdImageCreateFromGif( FILE *fd );

#endif
