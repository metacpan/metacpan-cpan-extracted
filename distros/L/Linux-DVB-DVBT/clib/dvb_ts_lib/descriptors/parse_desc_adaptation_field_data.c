/*
 * parse_desc_adaptation_field_data.c
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

#include "parse_desc_adaptation_field_data.h"
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
// adaptation_field_data_descriptor(){
//    descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  adaptation_field_data_identifier  8 bslbf
// }

	
/* ----------------------------------------------------------------------- */
void print_adaptation_field_data(struct Descriptor_adaptation_field_data *afdd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  adaptation_field_data [0x%02x]\n", afdd->descriptor_tag) ;
	printf("    Length: %d\n", afdd->descriptor_length) ;

	printf("    adaptation_field_data_identifier = %d\n", afdd->adaptation_field_data_identifier) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_adaptation_field_data(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_adaptation_field_data *afdd ;
unsigned byte ;
int end_buff_len ;

	afdd = (struct Descriptor_adaptation_field_data *)malloc( sizeof(*afdd) ) ;
	memset(afdd,0,sizeof(*afdd));

	//== Parse data ==
	INIT_LIST_HEAD(&afdd->next);
	afdd->descriptor_tag = tag ; // already extracted by parse_desc()
	afdd->descriptor_length = len ; // already extracted by parse_desc()
	afdd->adaptation_field_data_identifier = bits_get(bits, 8) ;
	
	return (struct Descriptor *)afdd ;
}
	
/* ----------------------------------------------------------------------- */
void free_adaptation_field_data(struct Descriptor_adaptation_field_data *afdd)
{
struct list_head  *item, *safe;
	
	free(afdd) ;
}
