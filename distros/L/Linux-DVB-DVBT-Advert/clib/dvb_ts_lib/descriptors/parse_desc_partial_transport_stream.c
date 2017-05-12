/*
 * parse_desc_partial_transport_stream.c
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

#include "parse_desc_partial_transport_stream.h"
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
// partial_transport_stream_descriptor() {
//  descriptor_tag  8 bslbf
//  descriptor_length  8 uimsbf
//  DVB_reserved_future_use  2 bslbf
//  peak_rate  22 uimsbf
//  DVB_reserved_future_use  2 bslbf
//  minimum_overall_smoothing_rate  22 uimsbf
//  DVB_reserved_future_use  2 bslbf
//  maximum_overall_smoothing_buffer  14 uimsbf
// }

	
/* ----------------------------------------------------------------------- */
void print_partial_transport_stream(struct Descriptor_partial_transport_stream *ptsd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  partial_transport_stream [0x%02x]\n", ptsd->descriptor_tag) ;
	printf("    Length: %d\n", ptsd->descriptor_length) ;

	printf("    peak_rate = %d\n", ptsd->peak_rate) ;
	printf("    minimum_overall_smoothing_rate = %d\n", ptsd->minimum_overall_smoothing_rate) ;
	printf("    maximum_overall_smoothing_buffer = %d\n", ptsd->maximum_overall_smoothing_buffer) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_partial_transport_stream(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_partial_transport_stream *ptsd ;
unsigned byte ;
int end_buff_len ;

	ptsd = (struct Descriptor_partial_transport_stream *)malloc( sizeof(*ptsd) ) ;
	memset(ptsd,0,sizeof(*ptsd));

	//== Parse data ==
	INIT_LIST_HEAD(&ptsd->next);
	ptsd->descriptor_tag = tag ; // already extracted by parse_desc()
	ptsd->descriptor_length = len ; // already extracted by parse_desc()
	bits_skip(bits, 2) ;
	ptsd->peak_rate = bits_get(bits, 22) ;
	bits_skip(bits, 2) ;
	ptsd->minimum_overall_smoothing_rate = bits_get(bits, 22) ;
	bits_skip(bits, 2) ;
	ptsd->maximum_overall_smoothing_buffer = bits_get(bits, 14) ;
	
	return (struct Descriptor *)ptsd ;
}
	
/* ----------------------------------------------------------------------- */
void free_partial_transport_stream(struct Descriptor_partial_transport_stream *ptsd)
{
struct list_head  *item, *safe;
	
	free(ptsd) ;
}
