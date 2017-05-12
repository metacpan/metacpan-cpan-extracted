/*
 * parse_desc_frequency_list.c
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

#include "parse_desc_frequency_list.h"
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
// frequency_list_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  reserved_future_use  6 bslbf
//  coding_type  2 bslbf
//  for (i=0;I<N;i++){
//   centre_frequency  32 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_frequency_list(struct Descriptor_frequency_list *fld, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  frequency_list [0x%02x]\n", fld->descriptor_tag) ;
	printf("    Length: %d\n", fld->descriptor_length) ;

	printf("    coding_type = %d\n", fld->coding_type) ;
	bits_dump("centre_frequency", fld->centre_frequency, fld->descriptor_length, 2) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_frequency_list(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_frequency_list *fld ;
unsigned byte ;
int end_buff_len ;

	fld = (struct Descriptor_frequency_list *)malloc( sizeof(*fld) ) ;
	memset(fld,0,sizeof(*fld));

	//== Parse data ==
	INIT_LIST_HEAD(&fld->next);
	fld->descriptor_tag = tag ; // already extracted by parse_desc()
	fld->descriptor_length = len ; // already extracted by parse_desc()
	bits_skip(bits, 6) ;
	fld->coding_type = bits_get(bits, 2) ;

	end_buff_len = bits_len_calc(bits, -(fld->descriptor_length - 1)) ;
	fld->centre_frequency[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_CENTRE_FREQUENCY_LEN); ++byte)
	{
		fld->centre_frequency[byte] = bits_get(bits, 8) ;
		fld->centre_frequency[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)fld ;
}
	
/* ----------------------------------------------------------------------- */
void free_frequency_list(struct Descriptor_frequency_list *fld)
{
struct list_head  *item, *safe;
	
	free(fld) ;
}
