/*
 * parse_desc_short_smoothing_buffer.c
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */


// VERSION = 1.00

/*=============================================================================================*/
// USES
/*=============================================================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>

#include "parse_desc_short_smoothing_buffer.h"
#include "descriptors/parse_desc.h"

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

/*=============================================================================================*/
// MACROS
/*=============================================================================================*/

/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
//
// short_smoothing_buffer_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  sb_size  2 uimsbf
//  sb_leak_rate  6 uimsbf
//  for (i=0;i<N;i++){
//   DVB_reserved  8 bslbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_short_smoothing_buffer(struct Descriptor_short_smoothing_buffer *ssbd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  short_smoothing_buffer [0x%02x]\n", ssbd->descriptor_tag) ;
	printf("    Length: %d\n", ssbd->descriptor_length) ;

	printf("    sb_size = %d\n", ssbd->sb_size) ;
	printf("    sb_leak_rate = %d\n", ssbd->sb_leak_rate) ;
	bits_dump("DVB_reserved", ssbd->DVB_reserved, ssbd->descriptor_length, 2) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_short_smoothing_buffer(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_short_smoothing_buffer *ssbd ;
unsigned byte ;
int end_buff_len ;

	ssbd = (struct Descriptor_short_smoothing_buffer *)malloc( sizeof(*ssbd) ) ;
	memset(ssbd,0,sizeof(*ssbd));

	//== Parse data ==
	INIT_LIST_HEAD(&ssbd->next);
	ssbd->descriptor_tag = tag ; // already extracted by parse_desc()
	ssbd->descriptor_length = len ; // already extracted by parse_desc()
	ssbd->sb_size = bits_get(bits, 2) ;
	ssbd->sb_leak_rate = bits_get(bits, 6) ;

	end_buff_len = bits_len_calc(bits, -(ssbd->descriptor_length - 1)) ;
	ssbd->DVB_reserved[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_DVB_RESERVED_LEN); ++byte)
	{
		ssbd->DVB_reserved[byte] = bits_get(bits, 8) ;
		ssbd->DVB_reserved[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)ssbd ;
}
	
/* ----------------------------------------------------------------------- */
void free_short_smoothing_buffer(struct Descriptor_short_smoothing_buffer *ssbd)
{
struct list_head  *item, *safe;
	
	free(ssbd) ;
}
