/*
 * parse_si_tdt.c
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

#include "parse_si_tdt.h"
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
// time_date_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  UTC_time  40 bslbf
// }

	
/* ----------------------------------------------------------------------- */
void print_tdt(struct Section_time_date *tdt)
{
struct list_head  *item, *safe;
int end_buff_len ;

	printf("Table:  time_date [0x%02x]\n", tdt->table_id) ;
	printf("Length: %d\n", tdt->section_length) ;

	//== data ==
	printf("section_syntax_indicator = %d\n", tdt->section_syntax_indicator) ;
	printf("UTC_time = %02d-%02d-%04d %02d:%02d:%02d\n", 
	    tdt->UTC_time.tm_mday, tdt->UTC_time.tm_mon, tdt->UTC_time.tm_year,
	    tdt->UTC_time.tm_hour, tdt->UTC_time.tm_min, tdt->UTC_time.tm_sec
	) ;
}
	
/* ----------------------------------------------------------------------- */
void parse_tdt(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags)
{
struct Section_time_date tdt ;
struct list_head  *item, *safe;
unsigned byte ;
int end_buff_len ;

	//== Parse data ==

	tdt.table_id = bits_get(bits, 8) ;
	tdt.section_syntax_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 1) ;
	bits_skip(bits, 2) ;
	tdt.section_length = bits_get(bits, 12) ;
	tdt.UTC_time = bits_get_mjd_time(bits) ;
	
	//== Call handler ==
	if (handler)
		handler(tsreader, tsstate, (struct Section *)&tdt, tsreader->user_data) ;

	//== Tidy up ==
}
