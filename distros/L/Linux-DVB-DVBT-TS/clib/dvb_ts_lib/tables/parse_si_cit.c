/*
 * parse_si_cit.c
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

#include "parse_si_cit.h"
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
// content_identifier_section() {
//     table_id 8 uimsbf
//     section_syntax_indicator 1 bslbf
//     private_indicator 1 bslbf
//     reserved 2 bslbf
//     section_length 12 uimsbf
//     service_id 16 uimsbf
//     reserved 2 bslbf
//     version_number 5 uimsbf
//     current_next_indicator 1 bslbf
//     section_number 8 uimsbf
//     last_section_number 8 uimsbf
//     transport_stream_id 16 uimsbf
//     original_network_id 16 uimsbf
//     prepend_strings_length 8 uimsbf
//     for (i=0; i< prepend_strings_length ; i++) {
//         prepend_strings_byte 8 uimsbf
//     }
//     for (j=0; j<N; j++) {
//         crid_ref 16 uimsbf
//         prepend_string_index 8 uimsbf
//         unique_string_length 8 uimsbf
//         for (k=0; k<unique_string_length; k++) {
//             unique_string_byte 8 uimsbf
//         }
//     }
//     CRC32 32 rpchof
// }

	
/* ----------------------------------------------------------------------- */
void print_cit(struct Section_content_identifier *cit)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  content_identifier [0x%02x]\n", cit->table_id) ;
	printf("Length: %d\n", cit->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", cit->section_syntax_indicator) ;
	printf("private_indicator = %d\n", cit->private_indicator) ;
	printf("service_id = %d\n", cit->service_id) ;
	printf("version_number = %d\n", cit->version_number) ;
	printf("current_next_indicator = %d\n", cit->current_next_indicator) ;
	printf("section_number = %d\n", cit->section_number) ;
	printf("last_section_number = %d\n", cit->last_section_number) ;
	printf("transport_stream_id = %d\n", cit->transport_stream_id) ;
	printf("original_network_id = %d\n", cit->original_network_id) ;
	printf("prepend_strings_length = %d\n", cit->prepend_strings_length) ;
	printf("prepend_strings = \"%s\"\n", cit->prepend_strings) ;
	
	list_for_each_safe(item,safe,&cit->cit_array) {
		struct CIT_entry *cit_entry = list_entry(item, struct CIT_entry, next);
		
		// CIT entry
		printf("  -CIT entry-\n") ;
		
		printf("  crid_ref = %d\n", cit_entry->crid_ref) ;
		printf("  prepend_string_index = %d\n", cit_entry->prepend_string_index) ;
		printf("  unique_string_length = %d\n", cit_entry->unique_string_length) ;
		printf("  unique_string = \"%s\"\n", cit_entry->unique_string) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
void parse_cit(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_content_identifier cit ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	cit.table_id = bits_get(bits, 8) ;
	cit.section_syntax_indicator = bits_get(bits, 1) ;
	cit.private_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 2) ;
	cit.section_length = bits_get(bits, 12) ;
	cit.service_id = bits_get(bits, 16) ;
	bits_skip(bits, 2) ;
	cit.version_number = bits_get(bits, 5) ;
	cit.current_next_indicator = bits_get(bits, 1) ;
	cit.section_number = bits_get(bits, 8) ;
	cit.last_section_number = bits_get(bits, 8) ;
	cit.transport_stream_id = bits_get(bits, 16) ;
	cit.original_network_id = bits_get(bits, 16) ;
	cit.prepend_strings_length = bits_get(bits, 8) ;

	end_buff_len = bits_len_calc(bits, -cit.prepend_strings_length) ;
	cit.prepend_strings[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_PREPEND_STRINGS_LEN); ++byte)
	{
		cit.prepend_strings[byte] = bits_get(bits, 8) ;
		cit.prepend_strings[byte+1] = 0 ;
	}

	
	INIT_LIST_HEAD(&cit.cit_array) ;
	while (bits->buff_len >= 4)
	{
		struct CIT_entry *cit_entry = malloc(sizeof(*cit_entry));
		memset(cit_entry,0,sizeof(*cit_entry));
		list_add_tail(&cit_entry->next,&cit.cit_array);

		cit_entry->crid_ref = bits_get(bits, 16) ;
		cit_entry->prepend_string_index = bits_get(bits, 8) ;
		cit_entry->unique_string_length = bits_get(bits, 8) ;

		end_buff_len = bits_len_calc(bits, -cit_entry->unique_string_length) ;
		cit_entry->unique_string[0] = 0 ;
		for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_UNIQUE_STRING_LEN); ++byte)
		{
			cit_entry->unique_string[byte] = bits_get(bits, 8) ;
			cit_entry->unique_string[byte+1] = 0 ;
		}

	}
	
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&cit, tsreader->user_data) ;

	//== Tidy up ==
	
	list_for_each_safe(item,safe,&cit.cit_array) {
		struct CIT_entry *cit_entry = list_entry(item, struct CIT_entry, next);
		free(cit_entry) ;
	}
	
}
