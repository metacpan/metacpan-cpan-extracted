/*
 * parse_desc_extended_event.c
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

#include "parse_desc_extended_event.h"
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
// extended_event_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  descriptor_number  4 uimsbf
//  last_descriptor_number  4 uimsbf
//  ISO_639_language_code  24 bslbf
//  length_of_items  8 uimsbf
//   for ( i=0;i<N;i++){
//   item_description_length  8 uimsbf
//   for (j=0;j<N;j++){
//    item_description_char  8 uimsbf
//     }
//   item_length  8 uimsbf
//   for (j=0;j<N;j++){
//    item_char  8 uimsbf
//     }
//  }
//  text_length   8 uimsbf
//  for (i=0;i<N;i++){
//   text_char  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_extended_event(struct Descriptor_extended_event *eed, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  extended_event [0x%02x]\n", eed->descriptor_tag) ;
	printf("    Length: %d\n", eed->descriptor_length) ;

	printf("    descriptor_number = %d\n", eed->descriptor_number) ;
	printf("    last_descriptor_number = %d\n", eed->last_descriptor_number) ;
	printf("    ISO_639_language_code = %d\n", eed->ISO_639_language_code) ;
	printf("    length_of_items = %d\n", eed->length_of_items) ;
	
	list_for_each_safe(item,safe,&eed->eed_array) {
		struct EED_entry *eed_entry = list_entry(item, struct EED_entry, next);
		
		// EED entry
		printf("      -EED entry-\n") ;
		
		printf("      item_description_length = %d\n", eed_entry->item_description_length) ;
		printf("      item_description = \"%s\"\n", eed_entry->item_description) ;
		printf("      item_length = %d\n", eed_entry->item_length) ;
		printf("      item = \"%s\"\n", eed_entry->item) ;
	}
	
	printf("    text_length = %d\n", eed->text_length) ;
	printf("    text = \"%s\"\n", eed->text) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_extended_event(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_extended_event *eed ;
unsigned byte ;
int end_buff_len ;

	eed = (struct Descriptor_extended_event *)malloc( sizeof(*eed) ) ;
	memset(eed,0,sizeof(*eed));

	//== Parse data ==
	INIT_LIST_HEAD(&eed->next);
	eed->descriptor_tag = tag ; // already extracted by parse_desc()
	eed->descriptor_length = len ; // already extracted by parse_desc()
	eed->descriptor_number = bits_get(bits, 4) ;
	eed->last_descriptor_number = bits_get(bits, 4) ;
	eed->ISO_639_language_code = bits_get(bits, 24) ;
	eed->length_of_items = bits_get(bits, 8) ;
	
	INIT_LIST_HEAD(&eed->eed_array) ;
	end_buff_len = bits_len_calc(bits, -(eed->descriptor_length - 5) ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct EED_entry *eed_entry = malloc(sizeof(*eed_entry));
		memset(eed_entry,0,sizeof(*eed_entry));
		list_add_tail(&eed_entry->next,&eed->eed_array);

		eed_entry->item_description_length = bits_get(bits, 8) ;

		end_buff_len = bits_len_calc(bits, -eed_entry->item_description_length) ;
		eed_entry->item_description[0] = 0 ;
		for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_ITEM_DESCRIPTION_LEN); ++byte)
		{
			eed_entry->item_description[byte] = bits_get(bits, 8) ;
			eed_entry->item_description[byte+1] = 0 ;
		}

		eed_entry->item_length = bits_get(bits, 8) ;

		end_buff_len = bits_len_calc(bits, -eed_entry->item_length) ;
		eed_entry->item[0] = 0 ;
		for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_ITEM_LEN); ++byte)
		{
			eed_entry->item[byte] = bits_get(bits, 8) ;
			eed_entry->item[byte+1] = 0 ;
		}

	}
	
	eed->text_length = bits_get(bits, 8) ;

	end_buff_len = bits_len_calc(bits, -eed->text_length) ;
	eed->text[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_TEXT_LEN); ++byte)
	{
		eed->text[byte] = bits_get(bits, 8) ;
		eed->text[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)eed ;
}
	
/* ----------------------------------------------------------------------- */
void free_extended_event(struct Descriptor_extended_event *eed)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&eed->eed_array) {
		struct EED_entry *eed_entry = list_entry(item, struct EED_entry, next);
		free(eed_entry) ;
	}
	
	
	free(eed) ;
}
