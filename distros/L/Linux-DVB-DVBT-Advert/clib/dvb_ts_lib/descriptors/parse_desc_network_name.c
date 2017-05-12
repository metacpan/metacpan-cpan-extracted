/*
 * parse_desc_network_name.c
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

#include "parse_desc_network_name.h"
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
// network_name_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   char  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_network_name(struct Descriptor_network_name *nnd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  network_name [0x%02x]\n", nnd->descriptor_tag) ;
	printf("    Length: %d\n", nnd->descriptor_length) ;

	printf("    descriptor = \"%s\"\n", nnd->descriptor) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_network_name(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_network_name *nnd ;
unsigned byte ;
int end_buff_len ;

	nnd = (struct Descriptor_network_name *)malloc( sizeof(*nnd) ) ;
	memset(nnd,0,sizeof(*nnd));

	//== Parse data ==
	INIT_LIST_HEAD(&nnd->next);
	nnd->descriptor_tag = tag ; // already extracted by parse_desc()
	nnd->descriptor_length = len ; // already extracted by parse_desc()

	end_buff_len = bits_len_calc(bits, -nnd->descriptor_length) ;
	nnd->descriptor[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_DESCRIPTOR_LEN); ++byte)
	{
		nnd->descriptor[byte] = bits_get(bits, 8) ;
		nnd->descriptor[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)nnd ;
}
	
/* ----------------------------------------------------------------------- */
void free_network_name(struct Descriptor_network_name *nnd)
{
struct list_head  *item, *safe;
	
	free(nnd) ;
}
