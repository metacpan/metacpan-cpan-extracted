/*
 * parse_desc_stream_identifier.c
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

#include "parse_desc_stream_identifier.h"
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
// stream_identifier_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  component_tag  8 uimsbf
// }

	
/* ----------------------------------------------------------------------- */
void print_stream_identifier(struct Descriptor_stream_identifier *sid, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  stream_identifier [0x%02x]\n", sid->descriptor_tag) ;
	printf("    Length: %d\n", sid->descriptor_length) ;

	printf("    component_tag = %d\n", sid->component_tag) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_stream_identifier(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_stream_identifier *sid ;
unsigned byte ;
int end_buff_len ;

	sid = (struct Descriptor_stream_identifier *)malloc( sizeof(*sid) ) ;
	memset(sid,0,sizeof(*sid));

	//== Parse data ==
	INIT_LIST_HEAD(&sid->next);
	sid->descriptor_tag = tag ; // already extracted by parse_desc()
	sid->descriptor_length = len ; // already extracted by parse_desc()
	sid->component_tag = bits_get(bits, 8) ;
	
	return (struct Descriptor *)sid ;
}
	
/* ----------------------------------------------------------------------- */
void free_stream_identifier(struct Descriptor_stream_identifier *sid)
{
struct list_head  *item, *safe;
	
	free(sid) ;
}
