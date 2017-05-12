/*
 * mpeg2_stubs.c
 *
 *  Created on: 27 Oct 2010
 *      Author: sdprice1
 */

#include <stdint.h>
#include <stdio.h>
#include "mpeg2.h"
#include "mpeg2convert.h"

static int rgb_internal (mpeg2convert_rgb_order_t order, unsigned int bpp,
		int stage, void * _id, const mpeg2_sequence_t * seq,
		int stride, uint32_t accel, void * arg,
		mpeg2_convert_init_t * result)
{
return 0 ;
}

#define DECLARE(func,order,bpp) \
int func (int stage, void * id, \
		const mpeg2_sequence_t * sequence, int stride, \
		uint32_t accel, void * arg, mpeg2_convert_init_t * result) \
{ \
	return rgb_internal (order, bpp, stage, id, sequence, stride, \
			accel, arg, result); \
}

DECLARE (mpeg2convert_rgb32, MPEG2CONVERT_RGB, 32)
DECLARE (mpeg2convert_rgb24, MPEG2CONVERT_RGB, 24)
DECLARE (mpeg2convert_rgb16, MPEG2CONVERT_RGB, 16)
DECLARE (mpeg2convert_rgb15, MPEG2CONVERT_RGB, 15)
DECLARE (mpeg2convert_rgb8, MPEG2CONVERT_RGB, 8)
DECLARE (mpeg2convert_bgr32, MPEG2CONVERT_BGR, 32)
DECLARE (mpeg2convert_bgr24, MPEG2CONVERT_BGR, 24)
DECLARE (mpeg2convert_bgr16, MPEG2CONVERT_BGR, 16)
DECLARE (mpeg2convert_bgr15, MPEG2CONVERT_BGR, 15)
DECLARE (mpeg2convert_bgr8, MPEG2CONVERT_BGR, 8)

uint32_t mpeg2_accel (uint32_t accel) {return 0;}
mpeg2dec_t * mpeg2_init (void) {return 0;}
const mpeg2_info_t * mpeg2_info (mpeg2dec_t * mpeg2dec) {return 0;}
void mpeg2_close (mpeg2dec_t * mpeg2dec) {}

void mpeg2_buffer (mpeg2dec_t * mpeg2dec, uint8_t * start, uint8_t * end) {}
int mpeg2_getpos (mpeg2dec_t * mpeg2dec) {return 0;}
mpeg2_state_t mpeg2_parse (mpeg2dec_t * mpeg2dec) {return 0;}

void mpeg2_reset (mpeg2dec_t * mpeg2dec, int full_reset) {}
void mpeg2_skip (mpeg2dec_t * mpeg2dec, int skip) {}
void mpeg2_slice_region (mpeg2dec_t * mpeg2dec, int start, int end) {}

void mpeg2_tag_picture (mpeg2dec_t * mpeg2dec, uint32_t tag, uint32_t tag2) {}

void mpeg2_init_fbuf (mpeg2_decoder_t * decoder, uint8_t * current_fbuf[3],
		      uint8_t * forward_fbuf[3], uint8_t * backward_fbuf[3]) {}
void mpeg2_slice (mpeg2_decoder_t * decoder, int code, const uint8_t * buffer) {}
int mpeg2_guess_aspect (const mpeg2_sequence_t * sequence,
			unsigned int * pixel_width,
			unsigned int * pixel_height) {return 0;}

void * mpeg2_malloc (unsigned size, mpeg2_alloc_t reason) {return 0;}
void mpeg2_free (void * buf) {}
void mpeg2_malloc_hooks (void * malloc (unsigned, mpeg2_alloc_t),
			 int free (void *)) {}

mpeg2_convert_t * mpeg2convert_rgb (mpeg2convert_rgb_order_t order,
				    unsigned int bpp) {return 0;}

int mpeg2_convert (mpeg2dec_t * mpeg2dec, mpeg2_convert_t convert, void * arg) {return 0;}

void dump_state (FILE * f, mpeg2_state_t state, const mpeg2_info_t * info,
		int offset, int verbose) {}




