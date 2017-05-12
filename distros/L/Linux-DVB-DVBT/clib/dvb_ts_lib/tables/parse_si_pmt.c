/*
 * parse_si_pmt.c
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

#include "parse_si_pmt.h"
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
// program_map_section() {
//     table_id 8 uimsbf
//     section_syntax_indicator 1 bslbf
//     '0' 1 bslbf
//     reserved 2 bslbf
//     section_length 12 uimsbf
//     program_number 16 uimsbf
//     reserved 2 bslbf
//     version_number 5 uimsbf
//     current_next_indicator 1 bslbf
//     section_number 8 uimsbf
//     last_section_number 8 uimsbf
//     reserved 3 bslbf
//     PCR_PID 13 uimsbf
//     reserved 4 bslbf
//     program_info_length 12 uimsbf
//     for (i = 0; i < N; i++) {
//         descriptor()
//     }
//     for (i = 0; i < N1; i++) {
//         stream_type 8 uimsbf
//         reserved 3 bslbf
//         elementary_PID 13 uimsbf
//         reserved 4 bslbf
//         ES_info_length 12 uimsbf
//         for (i = 0; i < N2; i++) {
//             descriptor()
//         }
//     }
//     CRC_32 32 rpchof
// }

	
/* ----------------------------------------------------------------------- */
void print_pmt(struct Section_program_map *pmt)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  program_map [0x%02x]\n", pmt->table_id) ;
	printf("Length: %d\n", pmt->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", pmt->section_syntax_indicator) ;
	printf("program_number = %d\n", pmt->program_number) ;
	printf("version_number = %d\n", pmt->version_number) ;
	printf("current_next_indicator = %d\n", pmt->current_next_indicator) ;
	printf("section_number = %d\n", pmt->section_number) ;
	printf("last_section_number = %d\n", pmt->last_section_number) ;
	printf("PCR_PID = %d\n", pmt->PCR_PID) ;
	printf("program_info_length = %d\n", pmt->program_info_length) ;
	
	// Descriptors list
	print_desc_list(&pmt->descriptors_array, 1) ;
	
	list_for_each_safe(item,safe,&pmt->pmt_array) {
		struct PMT_entry *pmt_entry = list_entry(item, struct PMT_entry, next);
		
		// PMT entry
		printf("  -PMT entry-\n") ;
		
		printf("  stream_type = %d\n", pmt_entry->stream_type) ;
		printf("  elementary_PID = %d\n", pmt_entry->elementary_PID) ;
		printf("  ES_info_length = %d\n", pmt_entry->ES_info_length) ;
		
		// Descriptors list
		print_desc_list(&pmt_entry->descriptors_array, 1) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
void parse_pmt(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_program_map pmt ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	pmt.table_id = bits_get(bits, 8) ;
	pmt.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	pmt.section_length = bits_get(bits, 12) ;
	pmt.program_number = bits_get(bits, 16) ;
	bits_skip(bits, 2) ;
	pmt.version_number = bits_get(bits, 5) ;
	pmt.current_next_indicator = bits_get(bits, 1) ;
	pmt.section_number = bits_get(bits, 8) ;
	pmt.last_section_number = bits_get(bits, 8) ;
	bits_skip(bits, 3) ;
	pmt.PCR_PID = bits_get(bits, 13) ;
	bits_skip(bits, 4) ;
	pmt.program_info_length = bits_get(bits, 12) ;

	// Descriptors
	INIT_LIST_HEAD(&pmt.descriptors_array);
	end_buff_len = bits_len_calc(bits, -pmt.program_info_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		enum TS_descriptor_ids desc_tag = parse_desc(&pmt.descriptors_array, bits, flags->decode_descriptor) ;
	}

	
	INIT_LIST_HEAD(&pmt.pmt_array) ;
	while (bits->buff_len >= 5)
	{
		struct PMT_entry *pmt_entry = malloc(sizeof(*pmt_entry));
		memset(pmt_entry,0,sizeof(*pmt_entry));
		list_add_tail(&pmt_entry->next,&pmt.pmt_array);

		pmt_entry->stream_type = bits_get(bits, 8) ;
		bits_skip(bits, 3) ;
		pmt_entry->elementary_PID = bits_get(bits, 13) ;
		bits_skip(bits, 4) ;
		pmt_entry->ES_info_length = bits_get(bits, 12) ;

		// Descriptors
		INIT_LIST_HEAD(&pmt_entry->descriptors_array);
		end_buff_len = bits_len_calc(bits, -pmt_entry->ES_info_length ) ;
		while (bits->buff_len > end_buff_len)
		{
			enum TS_descriptor_ids desc_tag = parse_desc(&pmt_entry->descriptors_array, bits, flags->decode_descriptor) ;
		}

	}
	
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&pmt, tsreader->user_data) ;

	//== Tidy up ==
	free_descriptors_list(&pmt.descriptors_array);
	
	list_for_each_safe(item,safe,&pmt.pmt_array) {
		struct PMT_entry *pmt_entry = list_entry(item, struct PMT_entry, next);
		free_descriptors_list(&pmt_entry->descriptors_array);
		free(pmt_entry) ;
	}
	
}
