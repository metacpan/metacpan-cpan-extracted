/*
 * parse_desc_bouquet_name.c
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

#include "parse_desc_bouquet_name.h"
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
// bouquet_name_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  for(i=0;i<N;i++){
//   char  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_bouquet_name(struct Descriptor_bouquet_name *bnd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  bouquet_name [0x%02x]\n", bnd->descriptor_tag) ;
	printf("    Length: %d\n", bnd->descriptor_length) ;

	printf("    descriptor = \"%s\"\n", bnd->descriptor) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_bouquet_name(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_bouquet_name *bnd ;
unsigned byte ;
int end_buff_len ;

	bnd = (struct Descriptor_bouquet_name *)malloc( sizeof(*bnd) ) ;
	memset(bnd,0,sizeof(*bnd));

	//== Parse data ==
	INIT_LIST_HEAD(&bnd->next);
	bnd->descriptor_tag = tag ; // already extracted by parse_desc()
	bnd->descriptor_length = len ; // already extracted by parse_desc()

	end_buff_len = bits_len_calc(bits, -bnd->descriptor_length) ;
	bnd->descriptor[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_DESCRIPTOR_LEN); ++byte)
	{
		bnd->descriptor[byte] = bits_get(bits, 8) ;
		bnd->descriptor[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)bnd ;
}
	
/* ----------------------------------------------------------------------- */
void free_bouquet_name(struct Descriptor_bouquet_name *bnd)
{
struct list_head  *item, *safe;
	
	free(bnd) ;
}
