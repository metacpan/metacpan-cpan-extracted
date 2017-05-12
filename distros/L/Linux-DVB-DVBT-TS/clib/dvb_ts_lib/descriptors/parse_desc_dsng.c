/*
 * parse_desc_dsng.c
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

#include "parse_desc_dsng.h"
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
// DSNG_descriptor (){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//   byte  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_dsng(struct Descriptor_dsng *dd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  dsng [0x%02x]\n", dd->descriptor_tag) ;
	printf("    Length: %d\n", dd->descriptor_length) ;

	printf("    byte = \"%s\"\n", dd->byte) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_dsng(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_dsng *dd ;
unsigned byte ;
int end_buff_len ;

	dd = (struct Descriptor_dsng *)malloc( sizeof(*dd) ) ;
	memset(dd,0,sizeof(*dd));

	//== Parse data ==
	INIT_LIST_HEAD(&dd->next);
	dd->descriptor_tag = tag ; // already extracted by parse_desc()
	dd->descriptor_length = len ; // already extracted by parse_desc()

	end_buff_len = bits_len_calc(bits, -dd->descriptor_length) ;
	dd->byte[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_BYTE_LEN); ++byte)
	{
		dd->byte[byte] = bits_get(bits, 8) ;
		dd->byte[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)dd ;
}
	
/* ----------------------------------------------------------------------- */
void free_dsng(struct Descriptor_dsng *dd)
{
struct list_head  *item, *safe;
	
	free(dd) ;
}
