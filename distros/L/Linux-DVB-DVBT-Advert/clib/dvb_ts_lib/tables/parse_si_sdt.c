/*
 * parse_si_sdt.c
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

#include "parse_si_sdt.h"
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
// service_description_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  transport_stream_id  16 uimsbf
//  reserved  2 bslbf
//  version_number  5 uimsbf
//  current_next_indicator  1 bslbf
//  section_number  8 uimsbf
//  last_section_number  8 uimsbf
//  original_network_id  16 uimsbf
//  reserved_future_use  8 bslbf
//  for (i=0;i<N;i++){
//   service_id  16 uimsbf
//   reserved_future_use  6 bslbf
//   EIT_schedule_flag  1 bslbf
//   EIT_present_following_flag  1 bslbf
//   running_status  3 uimsbf
//   free_CA_mode  1 bslbf
//   descriptors_loop_length  12 uimsbf
//   for (j=0;j<N;j++){
//    descriptor()
//     }
//  }
//  CRC_32  32 rpchof
// }

	
/* ----------------------------------------------------------------------- */
void print_sdt(struct Section_service_description *sdt)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  service_description [0x%02x]\n", sdt->table_id) ;
	printf("Length: %d\n", sdt->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", sdt->section_syntax_indicator) ;
	printf("transport_stream_id = %d\n", sdt->transport_stream_id) ;
	printf("version_number = %d\n", sdt->version_number) ;
	printf("current_next_indicator = %d\n", sdt->current_next_indicator) ;
	printf("section_number = %d\n", sdt->section_number) ;
	printf("last_section_number = %d\n", sdt->last_section_number) ;
	printf("original_network_id = %d\n", sdt->original_network_id) ;
	
	list_for_each_safe(item,safe,&sdt->sdt_array) {
		struct SDT_entry *sdt_entry = list_entry(item, struct SDT_entry, next);
		
		// SDT entry
		printf("  -SDT entry-\n") ;
		
		printf("  service_id = %d\n", sdt_entry->service_id) ;
		printf("  EIT_schedule_flag = %d\n", sdt_entry->EIT_schedule_flag) ;
		printf("  EIT_present_following_flag = %d\n", sdt_entry->EIT_present_following_flag) ;
		printf("  running_status = %d\n", sdt_entry->running_status) ;
		printf("  free_CA_mode = %d\n", sdt_entry->free_CA_mode) ;
		printf("  descriptors_loop_length = %d\n", sdt_entry->descriptors_loop_length) ;
		
		// Descriptors list
		print_desc_list(&sdt_entry->descriptors_array, 1) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
void parse_sdt(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_service_description sdt ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	sdt.table_id = bits_get(bits, 8) ;
	sdt.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	sdt.section_length = bits_get(bits, 12) ;
	sdt.transport_stream_id = bits_get(bits, 16) ;
	bits_skip(bits, 2) ;
	sdt.version_number = bits_get(bits, 5) ;
	sdt.current_next_indicator = bits_get(bits, 1) ;
	sdt.section_number = bits_get(bits, 8) ;
	sdt.last_section_number = bits_get(bits, 8) ;
	sdt.original_network_id = bits_get(bits, 16) ;
	bits_skip(bits, 8) ;
	
	INIT_LIST_HEAD(&sdt.sdt_array) ;
	while (bits->buff_len >= 5)
	{
		struct SDT_entry *sdt_entry = malloc(sizeof(*sdt_entry));
		memset(sdt_entry,0,sizeof(*sdt_entry));
		list_add_tail(&sdt_entry->next,&sdt.sdt_array);

		sdt_entry->service_id = bits_get(bits, 16) ;
		bits_skip(bits, 6) ;
		sdt_entry->EIT_schedule_flag = bits_get(bits, 1) ;
		sdt_entry->EIT_present_following_flag = bits_get(bits, 1) ;
		sdt_entry->running_status = bits_get(bits, 3) ;
		sdt_entry->free_CA_mode = bits_get(bits, 1) ;
		sdt_entry->descriptors_loop_length = bits_get(bits, 12) ;

		// Descriptors
		INIT_LIST_HEAD(&sdt_entry->descriptors_array);
		end_buff_len = bits_len_calc(bits, -sdt_entry->descriptors_loop_length ) ;
		while (bits->buff_len > end_buff_len)
		{
			enum TS_descriptor_ids desc_tag = parse_desc(&sdt_entry->descriptors_array, bits, flags->decode_descriptor) ;
		}

	}
	
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&sdt, tsreader->user_data) ;

	//== Tidy up ==
	
	list_for_each_safe(item,safe,&sdt.sdt_array) {
		struct SDT_entry *sdt_entry = list_entry(item, struct SDT_entry, next);
		free_descriptors_list(&sdt_entry->descriptors_array);
		free(sdt_entry) ;
	}
	
}
