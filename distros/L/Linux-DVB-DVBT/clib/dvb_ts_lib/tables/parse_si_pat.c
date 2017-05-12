/*
 * parse_si_pat.c
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

#include "parse_si_pat.h"
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
// program_association_section() {
//     table_id 8 uimsbf
//     section_syntax_indicator 1 bslbf
//     '0' 1 bslbf
//     reserved 2 bslbf
//     section_length 12 uimsbf
//     transport_stream_id 16 uimsbf
//     reserved 2 bslbf
//     version_number 5 uimsbf
//     current_next_indicator 1 bslbf
//     section_number 8 uimsbf
//     last_section_number 8 uimsbf
//     for (i = 0; i < N; i++) {
//         program_number 16 uimsbf
//         reserved 3 bslbf
//         if (program_number = = '0') {
//             network_PID 13 uimsbf
//         } else {
//             program_map_PID 13 uimsbf
//         }
//     }
//     CRC_32 32 rpchof
// }

	
/* ----------------------------------------------------------------------- */
void print_pat(struct Section_program_association *pat)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  program_association [0x%02x]\n", pat->table_id) ;
	printf("Length: %d\n", pat->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", pat->section_syntax_indicator) ;
	printf("transport_stream_id = %d\n", pat->transport_stream_id) ;
	printf("version_number = %d\n", pat->version_number) ;
	printf("current_next_indicator = %d\n", pat->current_next_indicator) ;
	printf("section_number = %d\n", pat->section_number) ;
	printf("last_section_number = %d\n", pat->last_section_number) ;
	
	list_for_each_safe(item,safe,&pat->pat_array) {
		struct PAT_entry *pat_entry = list_entry(item, struct PAT_entry, next);
		
		// PAT entry
		printf("  -PAT entry-\n") ;
		
		printf("  program_number = %d\n", pat_entry->program_number) ;
		if (pat_entry->program_number == 0x0  )
		{
		printf("  network_PID = %d\n", pat_entry->network_PID) ;
		}
		else
		{
		printf("  program_map_PID = %d\n", pat_entry->program_map_PID) ;
		}
		
	}
	
}
	
/* ----------------------------------------------------------------------- */
void parse_pat(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_program_association pat ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	pat.table_id = bits_get(bits, 8) ;
	pat.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	pat.section_length = bits_get(bits, 12) ;
	pat.transport_stream_id = bits_get(bits, 16) ;
	bits_skip(bits, 2) ;
	pat.version_number = bits_get(bits, 5) ;
	pat.current_next_indicator = bits_get(bits, 1) ;
	pat.section_number = bits_get(bits, 8) ;
	pat.last_section_number = bits_get(bits, 8) ;
	
	INIT_LIST_HEAD(&pat.pat_array) ;
	while (bits->buff_len >= 4)
	{
		struct PAT_entry *pat_entry = malloc(sizeof(*pat_entry));
		memset(pat_entry,0,sizeof(*pat_entry));
		list_add_tail(&pat_entry->next,&pat.pat_array);

		pat_entry->program_number = bits_get(bits, 16) ;
		bits_skip(bits, 3) ;
		if (pat_entry->program_number == 0x0  )
		{
		pat_entry->network_PID = bits_get(bits, 13) ;
		}
		else
		{
		pat_entry->program_map_PID = bits_get(bits, 13) ;
		}
		
	}
	
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&pat, tsreader->user_data) ;

	//== Tidy up ==
	
	list_for_each_safe(item,safe,&pat.pat_array) {
		struct PAT_entry *pat_entry = list_entry(item, struct PAT_entry, next);
		free(pat_entry) ;
	}
	
}
