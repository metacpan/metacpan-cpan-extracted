/*
 * parse_si_cat.c
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

#include "parse_si_cat.h"
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
// conditional_access_section() {
//     table_id 8 uimsbf
//     section_syntax_indicator 1 bslbf
//     '0' 1 bslbf
//     reserved 2 bslbf
//     section_length 12 uimsbf
//     reserved 18 bslbf
//     version_number 5 uimsbf
//     current_next_indicator 1 bslbf
//     section_number 8 uimsbf
//     last_section_number 8 uimsbf
//     for (i = 0; i < N; i++) {
//         descriptor()
//     }
//     CRC_32 32 rpchof
// }

	
/* ----------------------------------------------------------------------- */
void print_cat(struct Section_conditional_access *cat)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  conditional_access [0x%02x]\n", cat->table_id) ;
	printf("Length: %d\n", cat->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", cat->section_syntax_indicator) ;
	printf("version_number = %d\n", cat->version_number) ;
	printf("current_next_indicator = %d\n", cat->current_next_indicator) ;
	printf("section_number = %d\n", cat->section_number) ;
	printf("last_section_number = %d\n", cat->last_section_number) ;
	
	// Descriptors list
	print_desc_list(&cat->descriptors_array, 1) ;
}
	
/* ----------------------------------------------------------------------- */
void parse_cat(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_conditional_access cat ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	cat.table_id = bits_get(bits, 8) ;
	cat.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	cat.section_length = bits_get(bits, 12) ;
	bits_skip(bits, 18) ;
	cat.version_number = bits_get(bits, 5) ;
	cat.current_next_indicator = bits_get(bits, 1) ;
	cat.section_number = bits_get(bits, 8) ;
	cat.last_section_number = bits_get(bits, 8) ;

	// Descriptors
	INIT_LIST_HEAD(&cat.descriptors_array);
	end_buff_len = bits_len_calc(bits, -cat.section_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		enum TS_descriptor_ids desc_tag = parse_desc(&cat.descriptors_array, bits, flags->decode_descriptor) ;
	}

	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&cat, tsreader->user_data) ;

	//== Tidy up ==
	free_descriptors_list(&cat.descriptors_array);
}
