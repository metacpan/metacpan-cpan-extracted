/*
 * parse_desc_component.c
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

#include "parse_desc_component.h"
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
// component_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  reserved_future_use  4 bslbf
//  stream_content  4 uimsbf
//  component_type  8 uimsbf
//  component_tag  8 uimsbf
//  ISO_639_language_code   24 bslbf
//  for (i=0;i<N;i++){
//   text_char  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_component(struct Descriptor_component *cd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  component [0x%02x]\n", cd->descriptor_tag) ;
	printf("    Length: %d\n", cd->descriptor_length) ;

	printf("    stream_content = %d\n", cd->stream_content) ;
	printf("    component_type = %d\n", cd->component_type) ;
	printf("    component_tag = %d\n", cd->component_tag) ;
	printf("    ISO_639_language_code = %d\n", cd->ISO_639_language_code) ;
	printf("    text = \"%s\"\n", cd->text) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_component(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_component *cd ;
unsigned byte ;
int end_buff_len ;

	cd = (struct Descriptor_component *)malloc( sizeof(*cd) ) ;
	memset(cd,0,sizeof(*cd));

	//== Parse data ==
	INIT_LIST_HEAD(&cd->next);
	cd->descriptor_tag = tag ; // already extracted by parse_desc()
	cd->descriptor_length = len ; // already extracted by parse_desc()
	bits_skip(bits, 4) ;
	cd->stream_content = bits_get(bits, 4) ;
	cd->component_type = bits_get(bits, 8) ;
	cd->component_tag = bits_get(bits, 8) ;
	cd->ISO_639_language_code = bits_get(bits, 24) ;

	end_buff_len = bits_len_calc(bits, -(cd->descriptor_length - 6)) ;
	cd->text[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_TEXT_LEN); ++byte)
	{
		cd->text[byte] = bits_get(bits, 8) ;
		cd->text[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)cd ;
}
	
/* ----------------------------------------------------------------------- */
void free_component(struct Descriptor_component *cd)
{
struct list_head  *item, *safe;
	
	free(cd) ;
}
