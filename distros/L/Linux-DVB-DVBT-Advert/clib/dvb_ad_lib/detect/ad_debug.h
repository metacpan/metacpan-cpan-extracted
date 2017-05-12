/*
 * Frame statistics (blank, scene change) etc.
 *
 */

#ifndef AD_DEBUG_H_
#define AD_DEBUG_H_

#include <stdio.h>
#include <inttypes.h>


//---------------------------------------------------------------------------------------------------------------------------
void save_pgm (char *fmt, int width, int height,
		      int chroma_width, int chroma_height,
		      uint8_t * const * buf, int num) ;

void save_ppm (char *fmt, int width, int height, uint8_t * buf, int num) ;

#endif
