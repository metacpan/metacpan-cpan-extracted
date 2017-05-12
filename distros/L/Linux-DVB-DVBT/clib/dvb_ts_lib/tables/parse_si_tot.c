/*
 * parse_si_tot.c
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

#include "parse_si_tot.h"
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
// time_offset_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  UTC_time  40 bslbf
//  reserved  4 bslbf
//  descriptors_loop_length  12 uimsbf
//  for(i=0;i<N;i++){
//   descriptor()
//  }
//  CRC_32  32 rpchof
// }

	
/* ----------------------------------------------------------------------- */
void print_tot(struct Section_time_offset *tot)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  time_offset [0x%02x]\n", tot->table_id) ;
	printf("Length: %d\n", tot->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", tot->section_syntax_indicator) ;
	printf("UTC_time = %02d-%02d-%04d %02d:%02d:%02d\n", 
	    tot->UTC_time.tm_mday, tot->UTC_time.tm_mon, tot->UTC_time.tm_year,
	    tot->UTC_time.tm_hour, tot->UTC_time.tm_min, tot->UTC_time.tm_sec
	) ;
	printf("descriptors_loop_length = %d\n", tot->descriptors_loop_length) ;
	
	// Descriptors list
	print_desc_list(&tot->descriptors_array, 1) ;
}
	
/* ----------------------------------------------------------------------- */
void parse_tot(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_time_offset tot ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	tot.table_id = bits_get(bits, 8) ;
	tot.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	tot.section_length = bits_get(bits, 12) ;
	tot.UTC_time = bits_get_mjd_time(bits) ;
	bits_skip(bits, 4) ;
	tot.descriptors_loop_length = bits_get(bits, 12) ;

	// Descriptors
	INIT_LIST_HEAD(&tot.descriptors_array);
	end_buff_len = bits_len_calc(bits, -tot.descriptors_loop_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		enum TS_descriptor_ids desc_tag = parse_desc(&tot.descriptors_array, bits, flags->decode_descriptor) ;
	}

	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&tot, tsreader->user_data) ;

	//== Tidy up ==
	free_descriptors_list(&tot.descriptors_array);
}
