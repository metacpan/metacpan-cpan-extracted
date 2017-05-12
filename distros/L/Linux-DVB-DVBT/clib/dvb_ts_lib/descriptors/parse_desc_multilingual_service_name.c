/*
 * parse_desc_multilingual_service_name.c
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

#include "parse_desc_multilingual_service_name.h"
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
// multilingual_service_name_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//   ISO_639_language_code  24 bslbf
//   service_provider_name_length  8 uimsbf
//   for (j=0;j<N;j++){
//    char  8 uimsbf
//     }
//   service_name_length  8 uimsbf
//   for (j=0;j<N;j++){
//    char  8 uimsbf
//     }
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_multilingual_service_name(struct Descriptor_multilingual_service_name *msnd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  multilingual_service_name [0x%02x]\n", msnd->descriptor_tag) ;
	printf("    Length: %d\n", msnd->descriptor_length) ;

	
	list_for_each_safe(item,safe,&msnd->msnd_array) {
		struct MSND_entry *msnd_entry = list_entry(item, struct MSND_entry, next);
		
		// MSND entry
		printf("      -MSND entry-\n") ;
		
		printf("      ISO_639_language_code = %d\n", msnd_entry->ISO_639_language_code) ;
		printf("      service_provider_name_length = %d\n", msnd_entry->service_provider_name_length) ;
		printf("      service_provider_name = \"%s\"\n", msnd_entry->service_provider_name) ;
		printf("      service_name_length = %d\n", msnd_entry->service_name_length) ;
		printf("      service_name = \"%s\"\n", msnd_entry->service_name) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_multilingual_service_name(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_multilingual_service_name *msnd ;
unsigned byte ;
int end_buff_len ;

	msnd = (struct Descriptor_multilingual_service_name *)malloc( sizeof(*msnd) ) ;
	memset(msnd,0,sizeof(*msnd));

	//== Parse data ==
	INIT_LIST_HEAD(&msnd->next);
	msnd->descriptor_tag = tag ; // already extracted by parse_desc()
	msnd->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&msnd->msnd_array) ;
	end_buff_len = bits_len_calc(bits, -msnd->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct MSND_entry *msnd_entry = malloc(sizeof(*msnd_entry));
		memset(msnd_entry,0,sizeof(*msnd_entry));
		list_add_tail(&msnd_entry->next,&msnd->msnd_array);

		msnd_entry->ISO_639_language_code = bits_get(bits, 24) ;
		msnd_entry->service_provider_name_length = bits_get(bits, 8) ;

		end_buff_len = bits_len_calc(bits, -msnd_entry->service_provider_name_length) ;
		msnd_entry->service_provider_name[0] = 0 ;
		for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_SERVICE_PROVIDER_NAME_LEN); ++byte)
		{
			msnd_entry->service_provider_name[byte] = bits_get(bits, 8) ;
			msnd_entry->service_provider_name[byte+1] = 0 ;
		}

		msnd_entry->service_name_length = bits_get(bits, 8) ;

		end_buff_len = bits_len_calc(bits, -msnd_entry->service_name_length) ;
		msnd_entry->service_name[0] = 0 ;
		for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_SERVICE_NAME_LEN); ++byte)
		{
			msnd_entry->service_name[byte] = bits_get(bits, 8) ;
			msnd_entry->service_name[byte+1] = 0 ;
		}

	}
	
	
	return (struct Descriptor *)msnd ;
}
	
/* ----------------------------------------------------------------------- */
void free_multilingual_service_name(struct Descriptor_multilingual_service_name *msnd)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&msnd->msnd_array) {
		struct MSND_entry *msnd_entry = list_entry(item, struct MSND_entry, next);
		free(msnd_entry) ;
	}
	
	
	free(msnd) ;
}
