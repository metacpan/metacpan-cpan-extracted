/*
 * parse_desc_extension.c
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

#include "parse_desc_extension.h"
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
// extension_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  descriptor_tag_extension  8 uimsbf
//  for (i=0;i<N;i++){
//   selector_byte  8 bslbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_extension(struct Descriptor_extension *ed, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  extension [0x%02x]\n", ed->descriptor_tag) ;
	printf("    Length: %d\n", ed->descriptor_length) ;

	printf("    descriptor_tag_extension = %d\n", ed->descriptor_tag_extension) ;
	printf("    selector = \"%s\"\n", ed->selector) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_extension(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_extension *ed ;
unsigned byte ;
int end_buff_len ;

	ed = (struct Descriptor_extension *)malloc( sizeof(*ed) ) ;
	memset(ed,0,sizeof(*ed));

	//== Parse data ==
	INIT_LIST_HEAD(&ed->next);
	ed->descriptor_tag = tag ; // already extracted by parse_desc()
	ed->descriptor_length = len ; // already extracted by parse_desc()
	ed->descriptor_tag_extension = bits_get(bits, 8) ;

	end_buff_len = bits_len_calc(bits, -(ed->descriptor_length - 1)) ;
	ed->selector[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_SELECTOR_LEN); ++byte)
	{
		ed->selector[byte] = bits_get(bits, 8) ;
		ed->selector[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)ed ;
}
	
/* ----------------------------------------------------------------------- */
void free_extension(struct Descriptor_extension *ed)
{
struct list_head  *item, *safe;
	
	free(ed) ;
}
