/*
 * parse_desc_data_broadcast.c
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

#include "parse_desc_data_broadcast.h"
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
// data_broadcast_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  data_broadcast_id  16 uimsbf
//  component_tag  8 uimsbf
//  selector_length  8 uimsbf
//   for (i=0; i<selector_length; i++){
//   selector_byte  8 uimsbf
//  }
//  ISO_639_language_code  24 bslbf
//  text_length  8 uimsbf
//   for (i=0; i<text_length; i++){
//   text_char  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_data_broadcast(struct Descriptor_data_broadcast *dbd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  data_broadcast [0x%02x]\n", dbd->descriptor_tag) ;
	printf("    Length: %d\n", dbd->descriptor_length) ;

	printf("    data_broadcast_id = %d\n", dbd->data_broadcast_id) ;
	printf("    component_tag = %d\n", dbd->component_tag) ;
	printf("    selector_length = %d\n", dbd->selector_length) ;
	printf("    selector = \"%s\"\n", dbd->selector) ;
	printf("    ISO_639_language_code = %d\n", dbd->ISO_639_language_code) ;
	printf("    text_length = %d\n", dbd->text_length) ;
	printf("    text = \"%s\"\n", dbd->text) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_data_broadcast(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_data_broadcast *dbd ;
unsigned byte ;
int end_buff_len ;

	dbd = (struct Descriptor_data_broadcast *)malloc( sizeof(*dbd) ) ;
	memset(dbd,0,sizeof(*dbd));

	//== Parse data ==
	INIT_LIST_HEAD(&dbd->next);
	dbd->descriptor_tag = tag ; // already extracted by parse_desc()
	dbd->descriptor_length = len ; // already extracted by parse_desc()
	dbd->data_broadcast_id = bits_get(bits, 16) ;
	dbd->component_tag = bits_get(bits, 8) ;
	dbd->selector_length = bits_get(bits, 8) ;

	end_buff_len = bits_len_calc(bits, -dbd->selector_length) ;
	dbd->selector[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_SELECTOR_LEN); ++byte)
	{
		dbd->selector[byte] = bits_get(bits, 8) ;
		dbd->selector[byte+1] = 0 ;
	}

	dbd->ISO_639_language_code = bits_get(bits, 24) ;
	dbd->text_length = bits_get(bits, 8) ;

	end_buff_len = bits_len_calc(bits, -dbd->text_length) ;
	dbd->text[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_TEXT_LEN); ++byte)
	{
		dbd->text[byte] = bits_get(bits, 8) ;
		dbd->text[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)dbd ;
}
	
/* ----------------------------------------------------------------------- */
void free_data_broadcast(struct Descriptor_data_broadcast *dbd)
{
struct list_head  *item, *safe;
	
	free(dbd) ;
}
