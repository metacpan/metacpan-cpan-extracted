/*
 * parse_si_eit.c
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

#include "parse_si_eit.h"
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
// event_information_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  service_id  16 uimsbf
//  reserved  2 bslbf
//  version_number  5 uimsbf
//  current_next_indicator  1 bslbf
//  section_number  8 uimsbf
//  last_section_number  8 uimsbf
//  transport_stream_id  16 uimsbf
//  original_network_id  16 uimsbf
//  segment_last_section_number  8 uimsbf
//  last_table_id  8 uimsbf
//  for(i=0;i<N;i++){
//   event_id  16 uimsbf
//   start_time  40 bslbf
//   duration  24 uimsbf
//   running_status  3 uimsbf
//   free_CA_mode  1 bslbf
//   descriptors_loop_length  12 uimsbf
//   for(i=0;i<N;i++){
//    descriptor()
//     }
//  }
//  CRC_32  32 rpchof
// }

	
/* ----------------------------------------------------------------------- */
void print_eit(struct Section_event_information *eit)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  event_information [0x%02x]\n", eit->table_id) ;
	printf("Length: %d\n", eit->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", eit->section_syntax_indicator) ;
	printf("service_id = %d\n", eit->service_id) ;
	printf("version_number = %d\n", eit->version_number) ;
	printf("current_next_indicator = %d\n", eit->current_next_indicator) ;
	printf("section_number = %d\n", eit->section_number) ;
	printf("last_section_number = %d\n", eit->last_section_number) ;
	printf("transport_stream_id = %d\n", eit->transport_stream_id) ;
	printf("original_network_id = %d\n", eit->original_network_id) ;
	printf("segment_last_section_number = %d\n", eit->segment_last_section_number) ;
	printf("last_table_id = %d\n", eit->last_table_id) ;
	
	list_for_each_safe(item,safe,&eit->eit_array) {
		struct EIT_entry *eit_entry = list_entry(item, struct EIT_entry, next);
		
		// EIT entry
		printf("  -EIT entry-\n") ;
		
		printf("  event_id = %d\n", eit_entry->event_id) ;
		printf("  start_time = %02d-%02d-%04d %02d:%02d:%02d\n", 
		    eit_entry->start_time.tm_mday, eit_entry->start_time.tm_mon, eit_entry->start_time.tm_year,
		    eit_entry->start_time.tm_hour, eit_entry->start_time.tm_min, eit_entry->start_time.tm_sec
		) ;
		printf("  duration = %d\n", eit_entry->duration) ;
		printf("  running_status = %d\n", eit_entry->running_status) ;
		printf("  free_CA_mode = %d\n", eit_entry->free_CA_mode) ;
		printf("  descriptors_loop_length = %d\n", eit_entry->descriptors_loop_length) ;
		
		// Descriptors list
		print_desc_list(&eit_entry->descriptors_array, 1) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
void parse_eit(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_event_information eit ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	eit.table_id = bits_get(bits, 8) ;
	eit.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	eit.section_length = bits_get(bits, 12) ;
	eit.service_id = bits_get(bits, 16) ;
	bits_skip(bits, 2) ;
	eit.version_number = bits_get(bits, 5) ;
	eit.current_next_indicator = bits_get(bits, 1) ;
	eit.section_number = bits_get(bits, 8) ;
	eit.last_section_number = bits_get(bits, 8) ;
	eit.transport_stream_id = bits_get(bits, 16) ;
	eit.original_network_id = bits_get(bits, 16) ;
	eit.segment_last_section_number = bits_get(bits, 8) ;
	eit.last_table_id = bits_get(bits, 8) ;
	
	INIT_LIST_HEAD(&eit.eit_array) ;
	while (bits->buff_len >= 12)
	{
		struct EIT_entry *eit_entry = malloc(sizeof(*eit_entry));
		memset(eit_entry,0,sizeof(*eit_entry));
		list_add_tail(&eit_entry->next,&eit.eit_array);

		eit_entry->event_id = bits_get(bits, 16) ;
		eit_entry->start_time = bits_get_mjd_time(bits) ;
		eit_entry->duration = bits_get(bits, 24) ;
		eit_entry->running_status = bits_get(bits, 3) ;
		eit_entry->free_CA_mode = bits_get(bits, 1) ;
		eit_entry->descriptors_loop_length = bits_get(bits, 12) ;

		// Descriptors
		INIT_LIST_HEAD(&eit_entry->descriptors_array);
		end_buff_len = bits_len_calc(bits, -eit_entry->descriptors_loop_length ) ;
		while (bits->buff_len > end_buff_len)
		{
			enum TS_descriptor_ids desc_tag = parse_desc(&eit_entry->descriptors_array, bits, flags->decode_descriptor) ;
		}

	}
	
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&eit, tsreader->user_data) ;

	//== Tidy up ==
	
	list_for_each_safe(item,safe,&eit.eit_array) {
		struct EIT_entry *eit_entry = list_entry(item, struct EIT_entry, next);
		free_descriptors_list(&eit_entry->descriptors_array);
		free(eit_entry) ;
	}
	
}
