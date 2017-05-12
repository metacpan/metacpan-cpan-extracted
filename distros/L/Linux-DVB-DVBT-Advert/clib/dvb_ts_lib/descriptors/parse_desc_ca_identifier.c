/*
 * parse_desc_ca_identifier.c
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

#include "parse_desc_ca_identifier.h"
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
// CA_identifier_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   CA_system_id  16 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_ca_identifier(struct Descriptor_ca_identifier *cid, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  ca_identifier [0x%02x]\n", cid->descriptor_tag) ;
	printf("    Length: %d\n", cid->descriptor_length) ;

	bits_dump("CA_system_id", cid->CA_system_id, cid->descriptor_length, 2) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_ca_identifier(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_ca_identifier *cid ;
unsigned byte ;
int end_buff_len ;

	cid = (struct Descriptor_ca_identifier *)malloc( sizeof(*cid) ) ;
	memset(cid,0,sizeof(*cid));

	//== Parse data ==
	INIT_LIST_HEAD(&cid->next);
	cid->descriptor_tag = tag ; // already extracted by parse_desc()
	cid->descriptor_length = len ; // already extracted by parse_desc()

	end_buff_len = bits_len_calc(bits, -cid->descriptor_length) ;
	cid->CA_system_id[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_CA_SYSTEM_ID_LEN); ++byte)
	{
		cid->CA_system_id[byte] = bits_get(bits, 8) ;
		cid->CA_system_id[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)cid ;
}
	
/* ----------------------------------------------------------------------- */
void free_ca_identifier(struct Descriptor_ca_identifier *cid)
{
struct list_head  *item, *safe;
	
	free(cid) ;
}
