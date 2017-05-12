/*
 * parse_desc_time_shifted_service.c
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

#include "parse_desc_time_shifted_service.h"
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
// time_shifted_service_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  reference_service_id  16 uimsbf
// }

	
/* ----------------------------------------------------------------------- */
void print_time_shifted_service(struct Descriptor_time_shifted_service *tssd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  time_shifted_service [0x%02x]\n", tssd->descriptor_tag) ;
	printf("    Length: %d\n", tssd->descriptor_length) ;

	printf("    reference_service_id = %d\n", tssd->reference_service_id) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_time_shifted_service(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_time_shifted_service *tssd ;
unsigned byte ;
int end_buff_len ;

	tssd = (struct Descriptor_time_shifted_service *)malloc( sizeof(*tssd) ) ;
	memset(tssd,0,sizeof(*tssd));

	//== Parse data ==
	INIT_LIST_HEAD(&tssd->next);
	tssd->descriptor_tag = tag ; // already extracted by parse_desc()
	tssd->descriptor_length = len ; // already extracted by parse_desc()
	tssd->reference_service_id = bits_get(bits, 16) ;
	
	return (struct Descriptor *)tssd ;
}
	
/* ----------------------------------------------------------------------- */
void free_time_shifted_service(struct Descriptor_time_shifted_service *tssd)
{
struct list_head  *item, *safe;
	
	free(tssd) ;
}
