/*
 * parse_si_rst.c
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

#include "parse_si_rst.h"
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
// running_status_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  for (i=0;i<N;i++){
//   transport_stream_id   16 uimsbf
//   original_network_id   16 uimsbf
//   service_id  16 uimsbf
//   event_id  16 uimsbf
//   reserved_future_use  5 bslbf
//   running_status   3 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_rst(struct Section_running_status *rst)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  running_status [0x%02x]\n", rst->table_id) ;
	printf("Length: %d\n", rst->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", rst->section_syntax_indicator) ;
	
	list_for_each_safe(item,safe,&rst->rst_array) {
		struct RST_entry *rst_entry = list_entry(item, struct RST_entry, next);
		
		// RST entry
		printf("  -RST entry-\n") ;
		
		printf("  transport_stream_id = %d\n", rst_entry->transport_stream_id) ;
		printf("  original_network_id = %d\n", rst_entry->original_network_id) ;
		printf("  service_id = %d\n", rst_entry->service_id) ;
		printf("  event_id = %d\n", rst_entry->event_id) ;
		printf("  running_status = %d\n", rst_entry->running_status) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
void parse_rst(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_running_status rst ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	rst.table_id = bits_get(bits, 8) ;
	rst.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	rst.section_length = bits_get(bits, 12) ;
	
	INIT_LIST_HEAD(&rst.rst_array) ;
	while (bits->buff_len >= 9)
	{
		struct RST_entry *rst_entry = malloc(sizeof(*rst_entry));
		memset(rst_entry,0,sizeof(*rst_entry));
		list_add_tail(&rst_entry->next,&rst.rst_array);

		rst_entry->transport_stream_id = bits_get(bits, 16) ;
		rst_entry->original_network_id = bits_get(bits, 16) ;
		rst_entry->service_id = bits_get(bits, 16) ;
		rst_entry->event_id = bits_get(bits, 16) ;
		bits_skip(bits, 5) ;
		rst_entry->running_status = bits_get(bits, 3) ;
	}
	
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&rst, tsreader->user_data) ;

	//== Tidy up ==
	
	list_for_each_safe(item,safe,&rst.rst_array) {
		struct RST_entry *rst_entry = list_entry(item, struct RST_entry, next);
		free(rst_entry) ;
	}
	
}
