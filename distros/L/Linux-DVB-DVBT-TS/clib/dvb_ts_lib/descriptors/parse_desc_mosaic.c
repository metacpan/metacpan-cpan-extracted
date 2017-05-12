/*
 * parse_desc_mosaic.c
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

#include "parse_desc_mosaic.h"
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
// mosaic_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  mosaic_entry_point  1 bslbf
//  number_of_horizontal_elementary_cells   3 uimsbf
//  reserved_future_use  1 bslbf
//  number_of_vertical_elementary_cells   3 uimsbf
//   for (i=0;i<N; i++) {
//   logical_cell_id  6 uimsbf
//   reserved_future_use  7 bslbf
//   logical_cell_presentation_info  3 uimsbf
//   elementary_cell_field_length  8 uimsbf
//   for (i=0;j<elementary_cell_field_length;j++) {
//    reserved_future_use  2 bslbf
//    elementary_cell_id  6 uimsbf
//     }
//   cell_linkage_info   8 uimsbf
//   If (cell_linkage_info ==0x01){
//    bouquet_id  16 uimsbf
//     }
//   If (cell_linkage_info ==0x02){
//    original_network_id  16 uimsbf
//    transport_stream_id  16 uimsbf
//    service_id  16 uimsbf
//     }
//   If (cell_linkage_info ==0x03){
//    original_network_id  16 uimsbf
//    transport_stream_id  16 uimsbf
//    service_id  16 uimsbf
//     }
//   If (cell_linkage_info ==0x04){
//    original_network_id  16 uimsbf
//    transport_stream_id  16 uimsbf
//    service_id  16 uimsbf
//    event_id  16 uimsbf
//     }
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_mosaic(struct Descriptor_mosaic *md, int level)
{
struct list_head  *item, *safe;
struct list_head  *item1, *safe1;

	printf("    Descriptor:  mosaic [0x%02x]\n", md->descriptor_tag) ;
	printf("    Length: %d\n", md->descriptor_length) ;

	printf("    mosaic_entry_point = %d\n", md->mosaic_entry_point) ;
	printf("    number_of_horizontal_elementary_cells = %d\n", md->number_of_horizontal_elementary_cells) ;
	printf("    number_of_vertical_elementary_cells = %d\n", md->number_of_vertical_elementary_cells) ;
	
	list_for_each_safe(item,safe,&md->md_array) {
		struct MD_entry *md_entry = list_entry(item, struct MD_entry, next);
		
		// MD entry
		printf("      -MD entry-\n") ;
		
		printf("      logical_cell_id = %d\n", md_entry->logical_cell_id) ;
		printf("      logical_cell_presentation_info = %d\n", md_entry->logical_cell_presentation_info) ;
		printf("      elementary_cell_field_length = %d\n", md_entry->elementary_cell_field_length) ;
		
		list_for_each_safe(item1,safe1,&md_entry->md1_array) {
			struct MD1_entry *md1_entry = list_entry(item, struct MD1_entry, next);
			
			// MD entry
			printf("        -MD entry-\n") ;
			
			printf("        elementary_cell_id = %d\n", md1_entry->elementary_cell_id) ;
		}
		
		printf("      cell_linkage_info = %d\n", md_entry->cell_linkage_info) ;
		if (md_entry->cell_linkage_info == 0x1  )
		{
		printf("      bouquet_id = %d\n", md_entry->bouquet_id) ;
		}
		
		if (md_entry->cell_linkage_info == 0x2  )
		{
		printf("      original_network_id = %d\n", md_entry->original_network_id) ;
		printf("      transport_stream_id = %d\n", md_entry->transport_stream_id) ;
		printf("      service_id = %d\n", md_entry->service_id) ;
		}
		
		if (md_entry->cell_linkage_info == 0x3  )
		{
		printf("      original_network_id1 = %d\n", md_entry->original_network_id1) ;
		printf("      transport_stream_id1 = %d\n", md_entry->transport_stream_id1) ;
		printf("      service_id1 = %d\n", md_entry->service_id1) ;
		}
		
		if (md_entry->cell_linkage_info == 0x4  )
		{
		printf("      original_network_id2 = %d\n", md_entry->original_network_id2) ;
		printf("      transport_stream_id2 = %d\n", md_entry->transport_stream_id2) ;
		printf("      service_id2 = %d\n", md_entry->service_id2) ;
		printf("      event_id = %d\n", md_entry->event_id) ;
		}
		
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_mosaic(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_mosaic *md ;
unsigned byte ;
int end_buff_len ;

	md = (struct Descriptor_mosaic *)malloc( sizeof(*md) ) ;
	memset(md,0,sizeof(*md));

	//== Parse data ==
	INIT_LIST_HEAD(&md->next);
	md->descriptor_tag = tag ; // already extracted by parse_desc()
	md->descriptor_length = len ; // already extracted by parse_desc()
	md->mosaic_entry_point = bits_get(bits, 1) ;
	md->number_of_horizontal_elementary_cells = bits_get(bits, 3) ;
	bits_skip(bits, 1) ;
	md->number_of_vertical_elementary_cells = bits_get(bits, 3) ;
	
	INIT_LIST_HEAD(&md->md_array) ;
	end_buff_len = bits_len_calc(bits, -(md->descriptor_length - 1) ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct MD_entry *md_entry = malloc(sizeof(*md_entry));
		memset(md_entry,0,sizeof(*md_entry));
		list_add_tail(&md_entry->next,&md->md_array);

		md_entry->logical_cell_id = bits_get(bits, 6) ;
		bits_skip(bits, 7) ;
		md_entry->logical_cell_presentation_info = bits_get(bits, 3) ;
		md_entry->elementary_cell_field_length = bits_get(bits, 8) ;
		
		INIT_LIST_HEAD(&md_entry->md1_array) ;
		while (bits->buff_len >= 1)
		{
			struct MD1_entry *md1_entry = malloc(sizeof(*md1_entry));
			memset(md1_entry,0,sizeof(*md1_entry));
			list_add_tail(&md1_entry->next,&md_entry->md1_array);

			bits_skip(bits, 2) ;
			md1_entry->elementary_cell_id = bits_get(bits, 6) ;
		}
		
		md_entry->cell_linkage_info = bits_get(bits, 8) ;
		if (md_entry->cell_linkage_info == 0x1  )
		{
		md_entry->bouquet_id = bits_get(bits, 16) ;
		}
		
		if (md_entry->cell_linkage_info == 0x2  )
		{
		md_entry->original_network_id = bits_get(bits, 16) ;
		md_entry->transport_stream_id = bits_get(bits, 16) ;
		md_entry->service_id = bits_get(bits, 16) ;
		}
		
		if (md_entry->cell_linkage_info == 0x3  )
		{
		md_entry->original_network_id1 = bits_get(bits, 16) ;
		md_entry->transport_stream_id1 = bits_get(bits, 16) ;
		md_entry->service_id1 = bits_get(bits, 16) ;
		}
		
		if (md_entry->cell_linkage_info == 0x4  )
		{
		md_entry->original_network_id2 = bits_get(bits, 16) ;
		md_entry->transport_stream_id2 = bits_get(bits, 16) ;
		md_entry->service_id2 = bits_get(bits, 16) ;
		md_entry->event_id = bits_get(bits, 16) ;
		}
		
	}
	
	
	return (struct Descriptor *)md ;
}
	
/* ----------------------------------------------------------------------- */
void free_mosaic(struct Descriptor_mosaic *md)
{
struct list_head  *item, *safe;
struct list_head  *item1, *safe1;
	
	list_for_each_safe(item,safe,&md->md_array) {
		struct MD_entry *md_entry = list_entry(item, struct MD_entry, next);
		
		list_for_each_safe(item1,safe1,&md_entry->md1_array) {
			struct MD1_entry *md1_entry = list_entry(item, struct MD1_entry, next);
			free(md1_entry) ;
		}
		
		free(md_entry) ;
	}
	
	
	free(md) ;
}
