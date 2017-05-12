/*
 * parse_desc_s2_satellite_delivery_system.c
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

#include "parse_desc_s2_satellite_delivery_system.h"
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
// S2_satellite_delivery_system_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  scrambling_sequence_selector  1 bslbf
//  multiple_input_stream_flag  1 bslbf
//  backwards_compatibility_indicator  1 bslbf
//  reserved_future_use  5 bslbf
//   if (scrambling_sequence_selector == 1){
//   Reserved  6 bslbf
//   scrambling_sequence_index  18 uimsbf
//  }
//   if (multiple_input_stream_flag == 1){
//   input_stream_identifier  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_s2_satellite_delivery_system(struct Descriptor_s2_satellite_delivery_system *ssdsd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  s2_satellite_delivery_system [0x%02x]\n", ssdsd->descriptor_tag) ;
	printf("    Length: %d\n", ssdsd->descriptor_length) ;

	printf("    scrambling_sequence_selector = %d\n", ssdsd->scrambling_sequence_selector) ;
	printf("    multiple_input_stream_flag = %d\n", ssdsd->multiple_input_stream_flag) ;
	printf("    backwards_compatibility_indicator = %d\n", ssdsd->backwards_compatibility_indicator) ;
	if (ssdsd->scrambling_sequence_selector == 0x1  )
	{
	printf("    scrambling_sequence_index = %d\n", ssdsd->scrambling_sequence_index) ;
	}
	
	if (ssdsd->multiple_input_stream_flag == 0x1  )
	{
	printf("    input_stream_identifier = %d\n", ssdsd->input_stream_identifier) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_s2_satellite_delivery_system(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_s2_satellite_delivery_system *ssdsd ;
unsigned byte ;
int end_buff_len ;

	ssdsd = (struct Descriptor_s2_satellite_delivery_system *)malloc( sizeof(*ssdsd) ) ;
	memset(ssdsd,0,sizeof(*ssdsd));

	//== Parse data ==
	INIT_LIST_HEAD(&ssdsd->next);
	ssdsd->descriptor_tag = tag ; // already extracted by parse_desc()
	ssdsd->descriptor_length = len ; // already extracted by parse_desc()
	ssdsd->scrambling_sequence_selector = bits_get(bits, 1) ;
	ssdsd->multiple_input_stream_flag = bits_get(bits, 1) ;
	ssdsd->backwards_compatibility_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 5) ;
	if (ssdsd->scrambling_sequence_selector == 0x1  )
	{
	bits_skip(bits, 6) ;
	ssdsd->scrambling_sequence_index = bits_get(bits, 18) ;
	}
	
	if (ssdsd->multiple_input_stream_flag == 0x1  )
	{
	ssdsd->input_stream_identifier = bits_get(bits, 8) ;
	}
	
	
	return (struct Descriptor *)ssdsd ;
}
	
/* ----------------------------------------------------------------------- */
void free_s2_satellite_delivery_system(struct Descriptor_s2_satellite_delivery_system *ssdsd)
{
struct list_head  *item, *safe;
	
	free(ssdsd) ;
}
