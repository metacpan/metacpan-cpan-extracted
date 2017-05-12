/*
 * parse_si_dit.c
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

#include "parse_si_dit.h"
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
// discontinuity_information_section(){
//  table_id   8 uimsbf
//  section_syntax_indicator   1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  transition_flag  1 uimsbf
//  reserved_future_use  7 bslbf
// }

	
/* ----------------------------------------------------------------------- */
void print_dit(struct Section_discontinuity_information *dit)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  discontinuity_information [0x%02x]\n", dit->table_id) ;
	printf("Length: %d\n", dit->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", dit->section_syntax_indicator) ;
	printf("transition_flag = %d\n", dit->transition_flag) ;
}
	
/* ----------------------------------------------------------------------- */
void parse_dit(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_discontinuity_information dit ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	dit.table_id = bits_get(bits, 8) ;
	dit.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	dit.section_length = bits_get(bits, 12) ;
	dit.transition_flag = bits_get(bits, 1) ;
	bits_skip(bits, 7) ;
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&dit, tsreader->user_data) ;

	//== Tidy up ==
}
