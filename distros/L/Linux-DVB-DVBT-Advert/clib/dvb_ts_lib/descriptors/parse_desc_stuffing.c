/*
 * parse_desc_stuffing.c
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

#include "parse_desc_stuffing.h"
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
void print_stuffing(struct Descriptor_stuffing *sd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  stuffing [0x%02x]\n", sd->descriptor_tag) ;
	printf("    Length: %d\n", sd->descriptor_length) ;

	printf("    stuffing = \"%s\"\n", sd->stuffing) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_stuffing(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_stuffing *sd ;
unsigned byte ;
int end_buff_len ;

	sd = (struct Descriptor_stuffing *)malloc( sizeof(*sd) ) ;
	memset(sd,0,sizeof(*sd));

	//== Parse data ==
	INIT_LIST_HEAD(&sd->next);
	sd->descriptor_tag = tag ; // already extracted by parse_desc()
	sd->descriptor_length = len ; // already extracted by parse_desc()

	end_buff_len = bits_len_calc(bits, -sd->descriptor_length) ;
	sd->stuffing[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_STUFFING_LEN); ++byte)
	{
		sd->stuffing[byte] = bits_get(bits, 8) ;
		sd->stuffing[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)sd ;
}
	
/* ----------------------------------------------------------------------- */
void free_stuffing(struct Descriptor_stuffing *sd)
{
struct list_head  *item, *safe;
	
	free(sd) ;
}
