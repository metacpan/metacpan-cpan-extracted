/*
 * parse_si_sit.c
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

#include "parse_si_sit.h"
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
// selection_information_section(){
//  table_id   8 uimsbf
//  section_syntax_indicator   1 bslbf
//  DVB_reserved_future_use  1 bslbf
//  ISO_reserved  2 bslbf
//  section_length  12 uimsbf
//  DVB_reserved_future_use  16 uimsbf
//  ISO_reserved  2 bslbf
//  version_number  5 uimsbf
//  current_next_indicator  1 bslbf
//  section_number  8 uimsbf
//  last_section_number  8 uimsbf
//  DVB_reserved_for_future_use  4 uimsbf
//  transmission_info_loop_length  12 bslbf
//   for(i =0;i<N;i++) {
//   descriptor()
//  }
//  for(i=0;i<N;i++){
//   service_id  16 uimsbf
//   DVB_reserved_future_use  1 uimsbf
//   running_status  3 bslbf
//   service_loop_length  12 bslbf
//   for(j=0;j<N;j++){
//    descriptor()
//     }
//  }
//  CRC_32  32 rpchof
// }

	
/* ----------------------------------------------------------------------- */
void print_sit(struct Section_selection_information *sit)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  selection_information [0x%02x]\n", sit->table_id) ;
	printf("Length: %d\n", sit->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", sit->section_syntax_indicator) ;
	printf("version_number = %d\n", sit->version_number) ;
	printf("current_next_indicator = %d\n", sit->current_next_indicator) ;
	printf("section_number = %d\n", sit->section_number) ;
	printf("last_section_number = %d\n", sit->last_section_number) ;
	printf("transmission_info_loop_length = %d\n", sit->transmission_info_loop_length) ;
	
	// Descriptors list
	print_desc_list(&sit->transmission_info_array, 1) ;
	
	list_for_each_safe(item,safe,&sit->sit_array) {
		struct SIT_entry *sit_entry = list_entry(item, struct SIT_entry, next);
		
		// SIT entry
		printf("  -SIT entry-\n") ;
		
		printf("  service_id = %d\n", sit_entry->service_id) ;
		printf("  running_status = %d\n", sit_entry->running_status) ;
		printf("  service_loop_length = %d\n", sit_entry->service_loop_length) ;
		
		// Descriptors list
		print_desc_list(&sit_entry->service_array, 1) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
void parse_sit(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_selection_information sit ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	sit.table_id = bits_get(bits, 8) ;
	sit.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	sit.section_length = bits_get(bits, 12) ;
	bits_skip(bits, 16) ;
	bits_skip(bits, 2) ;
	sit.version_number = bits_get(bits, 5) ;
	sit.current_next_indicator = bits_get(bits, 1) ;
	sit.section_number = bits_get(bits, 8) ;
	sit.last_section_number = bits_get(bits, 8) ;
	bits_skip(bits, 4) ;
	sit.transmission_info_loop_length = bits_get(bits, 12) ;

	// Descriptors
	INIT_LIST_HEAD(&sit.transmission_info_array);
	end_buff_len = bits_len_calc(bits, -sit.transmission_info_loop_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		enum TS_descriptor_ids desc_tag = parse_desc(&sit.transmission_info_array, bits, flags->decode_descriptor) ;
	}

	
	INIT_LIST_HEAD(&sit.sit_array) ;
	while (bits->buff_len >= 4)
	{
		struct SIT_entry *sit_entry = malloc(sizeof(*sit_entry));
		memset(sit_entry,0,sizeof(*sit_entry));
		list_add_tail(&sit_entry->next,&sit.sit_array);

		sit_entry->service_id = bits_get(bits, 16) ;
		bits_skip(bits, 1) ;
		sit_entry->running_status = bits_get(bits, 3) ;
		sit_entry->service_loop_length = bits_get(bits, 12) ;

		// Descriptors
		INIT_LIST_HEAD(&sit_entry->service_array);
		end_buff_len = bits_len_calc(bits, -sit_entry->service_loop_length ) ;
		while (bits->buff_len > end_buff_len)
		{
			enum TS_descriptor_ids desc_tag = parse_desc(&sit_entry->service_array, bits, flags->decode_descriptor) ;
		}

	}
	
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&sit, tsreader->user_data) ;

	//== Tidy up ==
	free_descriptors_list(&sit.transmission_info_array);
	
	list_for_each_safe(item,safe,&sit.sit_array) {
		struct SIT_entry *sit_entry = list_entry(item, struct SIT_entry, next);
		free_descriptors_list(&sit_entry->service_array);
		free(sit_entry) ;
	}
	
}
