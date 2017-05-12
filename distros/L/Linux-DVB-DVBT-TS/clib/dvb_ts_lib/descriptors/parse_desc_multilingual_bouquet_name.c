/*
 * parse_desc_multilingual_bouquet_name.c
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

#include "parse_desc_multilingual_bouquet_name.h"
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
// multilingual_bouquet_name_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//   ISO_639_language_code  24 bslbf
//   bouquet_name_length  8 uimsbf
//   for (j=0;j<N;j++){
//    char  8 uimsbf
//     }
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_multilingual_bouquet_name(struct Descriptor_multilingual_bouquet_name *mbnd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  multilingual_bouquet_name [0x%02x]\n", mbnd->descriptor_tag) ;
	printf("    Length: %d\n", mbnd->descriptor_length) ;

	
	list_for_each_safe(item,safe,&mbnd->mbnd_array) {
		struct MBND_entry *mbnd_entry = list_entry(item, struct MBND_entry, next);
		
		// MBND entry
		printf("      -MBND entry-\n") ;
		
		printf("      ISO_639_language_code = %d\n", mbnd_entry->ISO_639_language_code) ;
		printf("      bouquet_name_length = %d\n", mbnd_entry->bouquet_name_length) ;
		printf("      bouquet_name = \"%s\"\n", mbnd_entry->bouquet_name) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_multilingual_bouquet_name(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_multilingual_bouquet_name *mbnd ;
unsigned byte ;
int end_buff_len ;

	mbnd = (struct Descriptor_multilingual_bouquet_name *)malloc( sizeof(*mbnd) ) ;
	memset(mbnd,0,sizeof(*mbnd));

	//== Parse data ==
	INIT_LIST_HEAD(&mbnd->next);
	mbnd->descriptor_tag = tag ; // already extracted by parse_desc()
	mbnd->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&mbnd->mbnd_array) ;
	end_buff_len = bits_len_calc(bits, -mbnd->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct MBND_entry *mbnd_entry = malloc(sizeof(*mbnd_entry));
		memset(mbnd_entry,0,sizeof(*mbnd_entry));
		list_add_tail(&mbnd_entry->next,&mbnd->mbnd_array);

		mbnd_entry->ISO_639_language_code = bits_get(bits, 24) ;
		mbnd_entry->bouquet_name_length = bits_get(bits, 8) ;

		end_buff_len = bits_len_calc(bits, -mbnd_entry->bouquet_name_length) ;
		mbnd_entry->bouquet_name[0] = 0 ;
		for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_BOUQUET_NAME_LEN); ++byte)
		{
			mbnd_entry->bouquet_name[byte] = bits_get(bits, 8) ;
			mbnd_entry->bouquet_name[byte+1] = 0 ;
		}

	}
	
	
	return (struct Descriptor *)mbnd ;
}
	
/* ----------------------------------------------------------------------- */
void free_multilingual_bouquet_name(struct Descriptor_multilingual_bouquet_name *mbnd)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&mbnd->mbnd_array) {
		struct MBND_entry *mbnd_entry = list_entry(item, struct MBND_entry, next);
		free(mbnd_entry) ;
	}
	
	
	free(mbnd) ;
}
