/*
 * parse_desc_ancillary_data.c
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

#include "parse_desc_ancillary_data.h"
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
// ancillary_data_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  ancillary_data_identifier  8 bslbf
// }

	
/* ----------------------------------------------------------------------- */
void print_ancillary_data(struct Descriptor_ancillary_data *add, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  ancillary_data [0x%02x]\n", add->descriptor_tag) ;
	printf("    Length: %d\n", add->descriptor_length) ;

	printf("    ancillary_data_identifier = %d\n", add->ancillary_data_identifier) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_ancillary_data(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_ancillary_data *add ;
unsigned byte ;
int end_buff_len ;

	add = (struct Descriptor_ancillary_data *)malloc( sizeof(*add) ) ;
	memset(add,0,sizeof(*add));

	//== Parse data ==
	INIT_LIST_HEAD(&add->next);
	add->descriptor_tag = tag ; // already extracted by parse_desc()
	add->descriptor_length = len ; // already extracted by parse_desc()
	add->ancillary_data_identifier = bits_get(bits, 8) ;
	
	return (struct Descriptor *)add ;
}
	
/* ----------------------------------------------------------------------- */
void free_ancillary_data(struct Descriptor_ancillary_data *add)
{
struct list_head  *item, *safe;
	
	free(add) ;
}
