/*
 * parse_si_nit.c
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

#include "parse_si_nit.h"
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
// network_information_section(){
//  table_id   8 uimsbf
//  section_syntax_indicator   1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  network_id  16 uimsbf
//  reserved  2 bslbf
//  version_number  5 uimsbf
//  current_next_indicator  1 bslbf
//  section_number  8 uimsbf
//  last_section_number  8 uimsbf
//  reserved_future_use  4 bslbf
//  network_descriptors_length  12 uimsbf
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
void print_nit(struct Section_network_information *nit)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  network_information [0x%02x]\n", nit->table_id) ;
	printf("Length: %d\n", nit->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", nit->section_syntax_indicator) ;
	printf("network_id = %d\n", nit->network_id) ;
	printf("version_number = %d\n", nit->version_number) ;
	printf("current_next_indicator = %d\n", nit->current_next_indicator) ;
	printf("section_number = %d\n", nit->section_number) ;
	printf("last_section_number = %d\n", nit->last_section_number) ;
	printf("network_descriptors_length = %d\n", nit->network_descriptors_length) ;
	
	// Descriptors list
	print_desc_list(&nit->network_array, 1) ;
	printf("transport_stream_loop_length = %d\n", nit->transport_stream_loop_length) ;
	
	list_for_each_safe(item,safe,&nit->nit_array) {
		struct NIT_entry *nit_entry = list_entry(item, struct NIT_entry, next);
		
		// NIT entry
		printf("  -NIT entry-\n") ;
		
		printf("  transport_stream_id = %d\n", nit_entry->transport_stream_id) ;
		printf("  original_network_id = %d\n", nit_entry->original_network_id) ;
		printf("  transport_descriptors_length = %d\n", nit_entry->transport_descriptors_length) ;
		
		// Descriptors list
		print_desc_list(&nit_entry->transport_array, 1) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
void parse_nit(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_network_information nit ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	nit.table_id = bits_get(bits, 8) ;
	nit.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	nit.section_length = bits_get(bits, 12) ;
	nit.network_id = bits_get(bits, 16) ;
	bits_skip(bits, 2) ;
	nit.version_number = bits_get(bits, 5) ;
	nit.current_next_indicator = bits_get(bits, 1) ;
	nit.section_number = bits_get(bits, 8) ;
	nit.last_section_number = bits_get(bits, 8) ;
	bits_skip(bits, 4) ;
	nit.network_descriptors_length = bits_get(bits, 12) ;

	// Descriptors
	INIT_LIST_HEAD(&nit.network_array);
	end_buff_len = bits_len_calc(bits, -nit.network_descriptors_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		enum TS_descriptor_ids desc_tag = parse_desc(&nit.network_array, bits, flags->decode_descriptor) ;
	}

	bits_skip(bits, 4) ;
	nit.transport_stream_loop_length = bits_get(bits, 12) ;
	
	INIT_LIST_HEAD(&nit.nit_array) ;
	while (bits->buff_len >= 6)
	{
		struct NIT_entry *nit_entry = malloc(sizeof(*nit_entry));
		memset(nit_entry,0,sizeof(*nit_entry));
		list_add_tail(&nit_entry->next,&nit.nit_array);

		nit_entry->transport_stream_id = bits_get(bits, 16) ;
		nit_entry->original_network_id = bits_get(bits, 16) ;
		bits_skip(bits, 4) ;
		nit_entry->transport_descriptors_length = bits_get(bits, 12) ;

		// Descriptors
		INIT_LIST_HEAD(&nit_entry->transport_array);
		end_buff_len = bits_len_calc(bits, -nit_entry->transport_descriptors_length ) ;
		while (bits->buff_len > end_buff_len)
		{
			enum TS_descriptor_ids desc_tag = parse_desc(&nit_entry->transport_array, bits, flags->decode_descriptor) ;
		}

	}
	
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&nit, tsreader->user_data) ;

	//== Tidy up ==
	free_descriptors_list(&nit.network_array);
	
	list_for_each_safe(item,safe,&nit.nit_array) {
		struct NIT_entry *nit_entry = list_entry(item, struct NIT_entry, next);
		free_descriptors_list(&nit_entry->transport_array);
		free(nit_entry) ;
	}
	
}
