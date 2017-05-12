/*
 * parse_desc_announcement_support.c
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

#include "parse_desc_announcement_support.h"
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
// announcement_support_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  announcement_support_indicator  16 bslbf
//   for (i=0; i<N; i++){
//   announcement_type  4 uimsbf
//   reserved_future_use  1 bslbf
//   reference_type  3 uimsbf
//     if (reference_type == 0x01
//    original_network_id  16 uimsbf
//    transport_stream_id  16 uimsbf
//    service_id  16 uimsbf
//    component_tag__  8 uimsbf
//     }
//     }
//  }

	
/* ----------------------------------------------------------------------- */
void print_announcement_support(struct Descriptor_announcement_support *asd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  announcement_support [0x%02x]\n", asd->descriptor_tag) ;
	printf("    Length: %d\n", asd->descriptor_length) ;

	printf("    announcement_support_indicator = %d\n", asd->announcement_support_indicator) ;
	
	list_for_each_safe(item,safe,&asd->asd_array) {
		struct ASD_entry *asd_entry = list_entry(item, struct ASD_entry, next);
		
		// ASD entry
		printf("      -ASD entry-\n") ;
		
		printf("      announcement_type = %d\n", asd_entry->announcement_type) ;
		printf("      reference_type = %d\n", asd_entry->reference_type) ;
		if (asd_entry->reference_type == 0x1 || asd_entry->reference_type == 0x2 || asd_entry->reference_type == 0x3  )
		{
		printf("      original_network_id = %d\n", asd_entry->original_network_id) ;
		printf("      transport_stream_id = %d\n", asd_entry->transport_stream_id) ;
		printf("      service_id = %d\n", asd_entry->service_id) ;
		printf("      component_tag = %d\n", asd_entry->component_tag) ;
		}
		
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_announcement_support(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_announcement_support *asd ;
unsigned byte ;
int end_buff_len ;

	asd = (struct Descriptor_announcement_support *)malloc( sizeof(*asd) ) ;
	memset(asd,0,sizeof(*asd));

	//== Parse data ==
	INIT_LIST_HEAD(&asd->next);
	asd->descriptor_tag = tag ; // already extracted by parse_desc()
	asd->descriptor_length = len ; // already extracted by parse_desc()
	asd->announcement_support_indicator = bits_get(bits, 16) ;
	
	INIT_LIST_HEAD(&asd->asd_array) ;
	end_buff_len = bits_len_calc(bits, -(asd->descriptor_length - 2) ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct ASD_entry *asd_entry = malloc(sizeof(*asd_entry));
		memset(asd_entry,0,sizeof(*asd_entry));
		list_add_tail(&asd_entry->next,&asd->asd_array);

		asd_entry->announcement_type = bits_get(bits, 4) ;
		bits_skip(bits, 1) ;
		asd_entry->reference_type = bits_get(bits, 3) ;
		if (asd_entry->reference_type == 0x1 || asd_entry->reference_type == 0x2 || asd_entry->reference_type == 0x3  )
		{
		asd_entry->original_network_id = bits_get(bits, 16) ;
		asd_entry->transport_stream_id = bits_get(bits, 16) ;
		asd_entry->service_id = bits_get(bits, 16) ;
		asd_entry->component_tag = bits_get(bits, 8) ;
		}
		
	}
	
	
	return (struct Descriptor *)asd ;
}
	
/* ----------------------------------------------------------------------- */
void free_announcement_support(struct Descriptor_announcement_support *asd)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&asd->asd_array) {
		struct ASD_entry *asd_entry = list_entry(item, struct ASD_entry, next);
		free(asd_entry) ;
	}
	
	
	free(asd) ;
}
