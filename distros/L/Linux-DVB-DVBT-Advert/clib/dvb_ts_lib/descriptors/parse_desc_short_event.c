/*
 * parse_desc_short_event.c
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

#include "parse_desc_short_event.h"
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
// short_event_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  ISO_639_language_code  24 bslbf
//  event_name_length  8 uimsbf
//  for (i=0;i<event_name_length;i++){
//   event_name_char  8 uimsbf
//  }
//  text_length  8 uimsbf
//  for (i=0;i<text_length;i++){
//   text_char  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_short_event(struct Descriptor_short_event *sed, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  short_event [0x%02x]\n", sed->descriptor_tag) ;
	printf("    Length: %d\n", sed->descriptor_length) ;

	printf("    ISO_639_language_code = %d\n", sed->ISO_639_language_code) ;
	printf("    event_name_length = %d\n", sed->event_name_length) ;
	printf("    event_name = \"%s\"\n", sed->event_name) ;
	printf("    text_length = %d\n", sed->text_length) ;
	printf("    text = \"%s\"\n", sed->text) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_short_event(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_short_event *sed ;
unsigned byte ;
int end_buff_len ;

	sed = (struct Descriptor_short_event *)malloc( sizeof(*sed) ) ;
	memset(sed,0,sizeof(*sed));

	//== Parse data ==
	INIT_LIST_HEAD(&sed->next);
	sed->descriptor_tag = tag ; // already extracted by parse_desc()
	sed->descriptor_length = len ; // already extracted by parse_desc()
	sed->ISO_639_language_code = bits_get(bits, 24) ;
	sed->event_name_length = bits_get(bits, 8) ;

	end_buff_len = bits_len_calc(bits, -sed->event_name_length) ;
	sed->event_name[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_EVENT_NAME_LEN); ++byte)
	{
		sed->event_name[byte] = bits_get(bits, 8) ;
		sed->event_name[byte+1] = 0 ;
	}

	sed->text_length = bits_get(bits, 8) ;

	end_buff_len = bits_len_calc(bits, -sed->text_length) ;
	sed->text[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_TEXT_LEN); ++byte)
	{
		sed->text[byte] = bits_get(bits, 8) ;
		sed->text[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)sed ;
}
	
/* ----------------------------------------------------------------------- */
void free_short_event(struct Descriptor_short_event *sed)
{
struct list_head  *item, *safe;
	
	free(sed) ;
}
