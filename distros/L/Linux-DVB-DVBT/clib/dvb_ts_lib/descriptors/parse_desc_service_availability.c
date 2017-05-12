/*
 * parse_desc_service_availability.c
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

#include "parse_desc_service_availability.h"
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
// service_availability_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  availability_flag  1 bslbf
//  reserved  7 bslbf
//   for (i=0;i<N;i++) {
//   cell_id  16 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_service_availability(struct Descriptor_service_availability *sad, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  service_availability [0x%02x]\n", sad->descriptor_tag) ;
	printf("    Length: %d\n", sad->descriptor_length) ;

	printf("    availability_flag = %d\n", sad->availability_flag) ;
	bits_dump("cell_id", sad->cell_id, sad->descriptor_length, 2) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_service_availability(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_service_availability *sad ;
unsigned byte ;
int end_buff_len ;

	sad = (struct Descriptor_service_availability *)malloc( sizeof(*sad) ) ;
	memset(sad,0,sizeof(*sad));

	//== Parse data ==
	INIT_LIST_HEAD(&sad->next);
	sad->descriptor_tag = tag ; // already extracted by parse_desc()
	sad->descriptor_length = len ; // already extracted by parse_desc()
	sad->availability_flag = bits_get(bits, 1) ;
	bits_skip(bits, 7) ;

	end_buff_len = bits_len_calc(bits, -(sad->descriptor_length - 1)) ;
	sad->cell_id[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_CELL_ID_LEN); ++byte)
	{
		sad->cell_id[byte] = bits_get(bits, 8) ;
		sad->cell_id[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)sad ;
}
	
/* ----------------------------------------------------------------------- */
void free_service_availability(struct Descriptor_service_availability *sad)
{
struct list_head  *item, *safe;
	
	free(sad) ;
}
