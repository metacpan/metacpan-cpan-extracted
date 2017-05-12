/*
 * parse_desc_multilingual_component.c
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

#include "parse_desc_multilingual_component.h"
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
// multilingual_component_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  component_tag  8 uimsbf
//   for (i=0;i<N;i++) {
//   ISO_639_language_code  24 bslbf
//   text_description_length  8 uimsbf
//   for (j=0;j<N;j++){
//    text_char  8 uimsbf
//     }
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_multilingual_component(struct Descriptor_multilingual_component *mcd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  multilingual_component [0x%02x]\n", mcd->descriptor_tag) ;
	printf("    Length: %d\n", mcd->descriptor_length) ;

	printf("    component_tag = %d\n", mcd->component_tag) ;
	
	list_for_each_safe(item,safe,&mcd->mcd_array) {
		struct MCD_entry *mcd_entry = list_entry(item, struct MCD_entry, next);
		
		// MCD entry
		printf("      -MCD entry-\n") ;
		
		printf("      ISO_639_language_code = %d\n", mcd_entry->ISO_639_language_code) ;
		printf("      text_description_length = %d\n", mcd_entry->text_description_length) ;
		printf("      text_description = \"%s\"\n", mcd_entry->text_description) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_multilingual_component(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_multilingual_component *mcd ;
unsigned byte ;
int end_buff_len ;

	mcd = (struct Descriptor_multilingual_component *)malloc( sizeof(*mcd) ) ;
	memset(mcd,0,sizeof(*mcd));

	//== Parse data ==
	INIT_LIST_HEAD(&mcd->next);
	mcd->descriptor_tag = tag ; // already extracted by parse_desc()
	mcd->descriptor_length = len ; // already extracted by parse_desc()
	mcd->component_tag = bits_get(bits, 8) ;
	
	INIT_LIST_HEAD(&mcd->mcd_array) ;
	end_buff_len = bits_len_calc(bits, -(mcd->descriptor_length - 1) ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct MCD_entry *mcd_entry = malloc(sizeof(*mcd_entry));
		memset(mcd_entry,0,sizeof(*mcd_entry));
		list_add_tail(&mcd_entry->next,&mcd->mcd_array);

		mcd_entry->ISO_639_language_code = bits_get(bits, 24) ;
		mcd_entry->text_description_length = bits_get(bits, 8) ;

		end_buff_len = bits_len_calc(bits, -mcd_entry->text_description_length) ;
		mcd_entry->text_description[0] = 0 ;
		for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_TEXT_DESCRIPTION_LEN); ++byte)
		{
			mcd_entry->text_description[byte] = bits_get(bits, 8) ;
			mcd_entry->text_description[byte+1] = 0 ;
		}

	}
	
	
	return (struct Descriptor *)mcd ;
}
	
/* ----------------------------------------------------------------------- */
void free_multilingual_component(struct Descriptor_multilingual_component *mcd)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&mcd->mcd_array) {
		struct MCD_entry *mcd_entry = list_entry(item, struct MCD_entry, next);
		free(mcd_entry) ;
	}
	
	
	free(mcd) ;
}
