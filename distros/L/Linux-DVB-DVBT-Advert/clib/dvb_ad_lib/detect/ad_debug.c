/*
 * Useful debug routines
 *
 */
#include <stdlib.h>
#include "ad_debug.h"

//---------------------------------------------------------------------------------------------------------------------------
void save_pgm (char *fmt, int width, int height,
		      int chroma_width, int chroma_height,
		      uint8_t * const * buf, int num)
{
    char filename[100];
    FILE * pgmfile;
    int i;
    static uint8_t black[16384] = { 0 };

    sprintf (filename, fmt, num);
fprintf(stderr, "Saving %s ...\n", filename);
    pgmfile = fopen (filename, "wb");
    if (!pgmfile) {
		fprintf (stderr, "Could not open file \"%s\".\n", filename);
		exit (1);
    }
    fprintf (pgmfile, "P5\n%d %d\n255\n",
	     2 * chroma_width, height + chroma_height);
    for (i = 0; i < height; i++) {
		fwrite (buf[0] + i * width, width, 1, pgmfile);
		fwrite (black, 2 * chroma_width - width, 1, pgmfile);
    }
    for (i = 0; i < chroma_height; i++) {
		fwrite (buf[1] + i * chroma_width, chroma_width, 1, pgmfile);
		fwrite (buf[2] + i * chroma_width, chroma_width, 1, pgmfile);
    }
    fclose (pgmfile);
}

//---------------------------------------------------------------------------------------------------------------------------
//PPM format:
//
//# A "magic number" for identifying the file type. A ppm image's magic number is the two characters "P6".
//# Whitespace (blanks, TABs, CRs, LFs).
//# A width, formatted as ASCII characters in decimal.
//# Whitespace.
//# A height, again in ASCII decimal.
//# Whitespace.
//# The maximum color value (Maxval), again in ASCII decimal. Must be less than 65536 and more than zero.
//# A single whitespace character (usually a newline).
//# A raster of Height rows, in order from top to bottom. Each row consists of Width pixels, in order from
//  left to right. Each pixel is a triplet of red, green, and blue samples, in that order. Each sample is
//  represented in pure binary by either 1 or 2 bytes. If the Maxval is less than 256, it is 1 byte.
//  Otherwise, it is 2 bytes. The most significant byte is first.
//
void save_ppm (char *fmt, int width, int height, uint8_t * buf, int num)
{
    char filename[100];
    FILE * ppmfile;

    sprintf (filename, fmt, num);
fprintf(stderr, "Saving %s ...\n", filename);
    ppmfile = fopen (filename, "wb");
    if (!ppmfile) {
	fprintf (stderr, "Could not open file \"%s\".\n", filename);
	exit (1);
    }
    fprintf (ppmfile, "P6\n%d %d\n255\n", width, height);
    fwrite (buf, 3 * width, height, ppmfile);
    fclose (ppmfile);
}
