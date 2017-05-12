/*
 * parse_desc_linkage.c
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

#include "parse_desc_linkage.h"
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
// linkage_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  transport_stream_id  16 uimsbf
//  original_network_id  16 uimsbf
//  service_id  16 uimsbf
//  linkage_type  8 uimsbf
//   if (linkage_type !=0x08){
//   for (i=0;i<N;i++){
//    private_data_byte  8 bslbf
//     }
//  }
//   if (linkage_type ==0x08){
//   hand_over_type  4 bslbf
//   reserved_future_use  3 bslbf
//   origin_type  1 bslbf
//   if (hand_over_type ==0x01
//    network_id  16 uimsbf
//     }
//   if (origin_type ==0x00){
//    initial_service_id  16 uimsbf
//     }
//   for (i=0;i<N;i++){
//    private_data_byte  8 bslbf
//     }
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_linkage(struct Descriptor_linkage *ld, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  linkage [0x%02x]\n", ld->descriptor_tag) ;
	printf("    Length: %d\n", ld->descriptor_length) ;

	printf("    transport_stream_id = %d\n", ld->transport_stream_id) ;
	printf("    original_network_id = %d\n", ld->original_network_id) ;
	printf("    service_id = %d\n", ld->service_id) ;
	printf("    linkage_type = %d\n", ld->linkage_type) ;
	if (ld->linkage_type != 0x8  )
	{
	printf("    private_data = \"%s\"\n", ld->private_data) ;
	}
	
	if (ld->linkage_type == 0x8  )
	{
	printf("    hand_over_type = %d\n", ld->hand_over_type) ;
	printf("    origin_type = %d\n", ld->origin_type) ;
	if (ld->hand_over_type == 0x1 || ld->hand_over_type == 0x2 || ld->hand_over_type == 0x3  )
	{
	printf("    network_id = %d\n", ld->network_id) ;
	}
	
	if (ld->origin_type == 0x0  )
	{
	printf("    initial_service_id = %d\n", ld->initial_service_id) ;
	}
	
	printf("    private_data1 = \"%s\"\n", ld->private_data1) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_linkage(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_linkage *ld ;
unsigned byte ;
int end_buff_len ;

	ld = (struct Descriptor_linkage *)malloc( sizeof(*ld) ) ;
	memset(ld,0,sizeof(*ld));

	//== Parse data ==
	INIT_LIST_HEAD(&ld->next);
	ld->descriptor_tag = tag ; // already extracted by parse_desc()
	ld->descriptor_length = len ; // already extracted by parse_desc()
	ld->transport_stream_id = bits_get(bits, 16) ;
	ld->original_network_id = bits_get(bits, 16) ;
	ld->service_id = bits_get(bits, 16) ;
	ld->linkage_type = bits_get(bits, 8) ;
	if (ld->linkage_type != 0x8  )
	{

	end_buff_len = bits_len_calc(bits, -(ld->descriptor_length - 7)) ;
	ld->private_data[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_PRIVATE_DATA_LEN); ++byte)
	{
		ld->private_data[byte] = bits_get(bits, 8) ;
		ld->private_data[byte+1] = 0 ;
	}

	}
	
	if (ld->linkage_type == 0x8  )
	{
	ld->hand_over_type = bits_get(bits, 4) ;
	bits_skip(bits, 3) ;
	ld->origin_type = bits_get(bits, 1) ;
	if (ld->hand_over_type == 0x1 || ld->hand_over_type == 0x2 || ld->hand_over_type == 0x3  )
	{
	ld->network_id = bits_get(bits, 16) ;
	}
	
	if (ld->origin_type == 0x0  )
	{
	ld->initial_service_id = bits_get(bits, 16) ;
	}
	

	end_buff_len = bits_len_calc(bits, -(ld->descriptor_length - 12)) ;
	ld->private_data1[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_PRIVATE_DATA1_LEN); ++byte)
	{
		ld->private_data1[byte] = bits_get(bits, 8) ;
		ld->private_data1[byte+1] = 0 ;
	}

	}
	
	
	return (struct Descriptor *)ld ;
}
	
/* ----------------------------------------------------------------------- */
void free_linkage(struct Descriptor_linkage *ld)
{
struct list_head  *item, *safe;
	
	free(ld) ;
}
