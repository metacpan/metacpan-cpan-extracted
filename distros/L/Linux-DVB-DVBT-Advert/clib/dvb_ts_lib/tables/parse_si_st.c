/*
 * parse_si_st.c
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

#include "parse_si_st.h"
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
// stuffing_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i= 0;i<N;i++){
//   stuffing_byte  8 bslbf
//  }
// }
// stuffing_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  for (i=0;i<N;i++){
//   data_byte   8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_st(struct Section_stuffing *st)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  stuffing [0x%02x]\n", st->table_id) ;
	printf("Length: %d\n", st->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", st->section_syntax_indicator) ;
	printf("section = \"%s\"\n", st->section) ;
}
	
/* ----------------------------------------------------------------------- */
void parse_st(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_stuffing st ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	st.table_id = bits_get(bits, 8) ;
	st.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	st.section_length = bits_get(bits, 12) ;

	end_buff_len = bits_len_calc(bits, -st.section_length) ;
	st.section[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_SECTION_LEN); ++byte)
	{
		st.section[byte] = bits_get(bits, 8) ;
		st.section[byte+1] = 0 ;
	}

	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&st, tsreader->user_data) ;

	//== Tidy up ==
}
