/*
 * parse_desc_data_broadcast_id.c
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

#include "parse_desc_data_broadcast_id.h"
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
// data_broadcast_id_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  data_broadcast_id  16 uimsbf
//   for(i=0; i < N;i++){
//   id_selector_byte  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_data_broadcast_id(struct Descriptor_data_broadcast_id *dbid, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  data_broadcast_id [0x%02x]\n", dbid->descriptor_tag) ;
	printf("    Length: %d\n", dbid->descriptor_length) ;

	printf("    data_broadcast_id = %d\n", dbid->data_broadcast_id) ;
	printf("    id_selector = \"%s\"\n", dbid->id_selector) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_data_broadcast_id(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_data_broadcast_id *dbid ;
unsigned byte ;
int end_buff_len ;

	dbid = (struct Descriptor_data_broadcast_id *)malloc( sizeof(*dbid) ) ;
	memset(dbid,0,sizeof(*dbid));

	//== Parse data ==
	INIT_LIST_HEAD(&dbid->next);
	dbid->descriptor_tag = tag ; // already extracted by parse_desc()
	dbid->descriptor_length = len ; // already extracted by parse_desc()
	dbid->data_broadcast_id = bits_get(bits, 16) ;

	end_buff_len = bits_len_calc(bits, -(dbid->descriptor_length - 2)) ;
	dbid->id_selector[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_ID_SELECTOR_LEN); ++byte)
	{
		dbid->id_selector[byte] = bits_get(bits, 8) ;
		dbid->id_selector[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)dbid ;
}
	
/* ----------------------------------------------------------------------- */
void free_data_broadcast_id(struct Descriptor_data_broadcast_id *dbid)
{
struct list_head  *item, *safe;
	
	free(dbid) ;
}
