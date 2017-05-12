/*
 * parse_si_bat.c
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

#include "parse_si_bat.h"
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
// bouquet_association_section(){
//  table_id   8 uimsbf
//  section_syntax_indicator   1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  bouquet_id  16 uimsbf
//  reserved  2 bslbf
//  version_number  5 uimsbf
//  current_next_indicator  1 bslbf
//  section_number  8 uimsbf
//  last_section_number  8 uimsbf
//  reserved_future_use  4 bslbf
//  bouquet_descriptors_length  12 uimsbf
//  for(i=0;i<N;i++){
//   descriptor()
//  }
//  reserved_future_use  4 bslbf
//  transport_stream_loop_length  12 uimsbf
//  for(i=0;i<N;i++){
//   transport_stream_id  16 uimsbf
//   original_network_id  16 uimsbf
//   reserved_future_use  4 bslbf
//   transport_descriptors_length  12 uimsbf
//   for(j=0;j<N;j++){
//    descriptor()
//     }
//  }
//  CRC_32  32 rpchof
// }

	
/* ----------------------------------------------------------------------- */
void print_bat(struct Section_bouquet_association *bat)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  bouquet_association [0x%02x]\n", bat->table_id) ;
	printf("Length: %d\n", bat->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", bat->section_syntax_indicator) ;
	printf("bouquet_id = %d\n", bat->bouquet_id) ;
	printf("version_number = %d\n", bat->version_number) ;
	printf("current_next_indicator = %d\n", bat->current_next_indicator) ;
	printf("section_number = %d\n", bat->section_number) ;
	printf("last_section_number = %d\n", bat->last_section_number) ;
	printf("bouquet_descriptors_length = %d\n", bat->bouquet_descriptors_length) ;
	
	// Descriptors list
	print_desc_list(&bat->bouquet_array, 1) ;
	printf("transport_stream_loop_length = %d\n", bat->transport_stream_loop_length) ;
	
	list_for_each_safe(item,safe,&bat->bat_array) {
		struct BAT_entry *bat_entry = list_entry(item, struct BAT_entry, next);
		
		// BAT entry
		printf("  -BAT entry-\n") ;
		
		printf("  transport_stream_id = %d\n", bat_entry->transport_stream_id) ;
		printf("  original_network_id = %d\n", bat_entry->original_network_id) ;
		printf("  transport_descriptors_length = %d\n", bat_entry->transport_descriptors_length) ;
		
		// Descriptors list
		print_desc_list(&bat_entry->transport_array, 1) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
void parse_bat(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_bouquet_association bat ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	bat.table_id = bits_get(bits, 8) ;
	bat.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	bat.section_length = bits_get(bits, 12) ;
	bat.bouquet_id = bits_get(bits, 16) ;
	bits_skip(bits, 2) ;
	bat.version_number = bits_get(bits, 5) ;
	bat.current_next_indicator = bits_get(bits, 1) ;
	bat.section_number = bits_get(bits, 8) ;
	bat.last_section_number = bits_get(bits, 8) ;
	bits_skip(bits, 4) ;
	bat.bouquet_descriptors_length = bits_get(bits, 12) ;

	// Descriptors
	INIT_LIST_HEAD(&bat.bouquet_array);
	end_buff_len = bits_len_calc(bits, -bat.bouquet_descriptors_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		enum TS_descriptor_ids desc_tag = parse_desc(&bat.bouquet_array, bits, flags->decode_descriptor) ;
	}

	bits_skip(bits, 4) ;
	bat.transport_stream_loop_length = bits_get(bits, 12) ;
	
	INIT_LIST_HEAD(&bat.bat_array) ;
	while (bits->buff_len >= 6)
	{
		struct BAT_entry *bat_entry = malloc(sizeof(*bat_entry));
		memset(bat_entry,0,sizeof(*bat_entry));
		list_add_tail(&bat_entry->next,&bat.bat_array);

		bat_entry->transport_stream_id = bits_get(bits, 16) ;
		bat_entry->original_network_id = bits_get(bits, 16) ;
		bits_skip(bits, 4) ;
		bat_entry->transport_descriptors_length = bits_get(bits, 12) ;

		// Descriptors
		INIT_LIST_HEAD(&bat_entry->transport_array);
		end_buff_len = bits_len_calc(bits, -bat_entry->transport_descriptors_length ) ;
		while (bits->buff_len > end_buff_len)
		{
			enum TS_descriptor_ids desc_tag = parse_desc(&bat_entry->transport_array, bits, flags->decode_descriptor) ;
		}

	}
	
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&bat, tsreader->user_data) ;

	//== Tidy up ==
	free_descriptors_list(&bat.bouquet_array);
	
	list_for_each_safe(item,safe,&bat.bat_array) {
		struct BAT_entry *bat_entry = list_entry(item, struct BAT_entry, next);
		free_descriptors_list(&bat_entry->transport_array);
		free(bat_entry) ;
	}
	
}
