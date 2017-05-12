/*
 * parse_desc_service_move.c
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

#include "parse_desc_service_move.h"
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
// service_move_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  new_original_network_id  16 uimsbf
//  new_transport_stream_id  16 uimsbf
//  new_service_id  16 uimsbf
// }

	
/* ----------------------------------------------------------------------- */
void print_service_move(struct Descriptor_service_move *smd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  service_move [0x%02x]\n", smd->descriptor_tag) ;
	printf("    Length: %d\n", smd->descriptor_length) ;

	printf("    new_original_network_id = %d\n", smd->new_original_network_id) ;
	printf("    new_transport_stream_id = %d\n", smd->new_transport_stream_id) ;
	printf("    new_service_id = %d\n", smd->new_service_id) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_service_move(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_service_move *smd ;
unsigned byte ;
int end_buff_len ;

	smd = (struct Descriptor_service_move *)malloc( sizeof(*smd) ) ;
	memset(smd,0,sizeof(*smd));

	//== Parse data ==
	INIT_LIST_HEAD(&smd->next);
	smd->descriptor_tag = tag ; // already extracted by parse_desc()
	smd->descriptor_length = len ; // already extracted by parse_desc()
	smd->new_original_network_id = bits_get(bits, 16) ;
	smd->new_transport_stream_id = bits_get(bits, 16) ;
	smd->new_service_id = bits_get(bits, 16) ;
	
	return (struct Descriptor *)smd ;
}
	
/* ----------------------------------------------------------------------- */
void free_service_move(struct Descriptor_service_move *smd)
{
struct list_head  *item, *safe;
	
	free(smd) ;
}
