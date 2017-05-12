/*
 * parse_desc_pdc.c
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

#include "parse_desc_pdc.h"
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
// PDC_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length   8 uimsbf
//  reserved_future_use   4 bslbf
//  programme_identification_label  20 bslbf
// }

	
/* ----------------------------------------------------------------------- */
void print_pdc(struct Descriptor_pdc *pd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  pdc [0x%02x]\n", pd->descriptor_tag) ;
	printf("    Length: %d\n", pd->descriptor_length) ;

	printf("    programme_identification_label = %d\n", pd->programme_identification_label) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_pdc(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_pdc *pd ;
unsigned byte ;
int end_buff_len ;

	pd = (struct Descriptor_pdc *)malloc( sizeof(*pd) ) ;
	memset(pd,0,sizeof(*pd));

	//== Parse data ==
	INIT_LIST_HEAD(&pd->next);
	pd->descriptor_tag = tag ; // already extracted by parse_desc()
	pd->descriptor_length = len ; // already extracted by parse_desc()
	bits_skip(bits, 4) ;
	pd->programme_identification_label = bits_get(bits, 20) ;
	
	return (struct Descriptor *)pd ;
}
	
/* ----------------------------------------------------------------------- */
void free_pdc(struct Descriptor_pdc *pd)
{
struct list_head  *item, *safe;
	
	free(pd) ;
}
