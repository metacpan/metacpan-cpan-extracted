/*
 * parse_desc_multilingual_network_name.c
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

#include "parse_desc_multilingual_network_name.h"
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
// multilingual_network_name_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//   ISO_639_language_code  24 bslbf
//   network_name_length  8 uimsbf
//   for (j=0;j<N;j++){
//    char  8 uimsbf
//     }
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_multilingual_network_name(struct Descriptor_multilingual_network_name *mnnd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  multilingual_network_name [0x%02x]\n", mnnd->descriptor_tag) ;
	printf("    Length: %d\n", mnnd->descriptor_length) ;

	
	list_for_each_safe(item,safe,&mnnd->mnnd_array) {
		struct MNND_entry *mnnd_entry = list_entry(item, struct MNND_entry, next);
		
		// MNND entry
		printf("      -MNND entry-\n") ;
		
		printf("      ISO_639_language_code = %d\n", mnnd_entry->ISO_639_language_code) ;
		printf("      network_name_length = %d\n", mnnd_entry->network_name_length) ;
		printf("      network_name = \"%s\"\n", mnnd_entry->network_name) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_multilingual_network_name(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_multilingual_network_name *mnnd ;
unsigned byte ;
int end_buff_len ;

	mnnd = (struct Descriptor_multilingual_network_name *)malloc( sizeof(*mnnd) ) ;
	memset(mnnd,0,sizeof(*mnnd));

	//== Parse data ==
	INIT_LIST_HEAD(&mnnd->next);
	mnnd->descriptor_tag = tag ; // already extracted by parse_desc()
	mnnd->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&mnnd->mnnd_array) ;
	end_buff_len = bits_len_calc(bits, -mnnd->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct MNND_entry *mnnd_entry = malloc(sizeof(*mnnd_entry));
		memset(mnnd_entry,0,sizeof(*mnnd_entry));
		list_add_tail(&mnnd_entry->next,&mnnd->mnnd_array);

		mnnd_entry->ISO_639_language_code = bits_get(bits, 24) ;
		mnnd_entry->network_name_length = bits_get(bits, 8) ;

		end_buff_len = bits_len_calc(bits, -mnnd_entry->network_name_length) ;
		mnnd_entry->network_name[0] = 0 ;
		for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_NETWORK_NAME_LEN); ++byte)
		{
			mnnd_entry->network_name[byte] = bits_get(bits, 8) ;
			mnnd_entry->network_name[byte+1] = 0 ;
		}

	}
	
	
	return (struct Descriptor *)mnnd ;
}
	
/* ----------------------------------------------------------------------- */
void free_multilingual_network_name(struct Descriptor_multilingual_network_name *mnnd)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&mnnd->mnnd_array) {
		struct MNND_entry *mnnd_entry = list_entry(item, struct MNND_entry, next);
		free(mnnd_entry) ;
	}
	
	
	free(mnnd) ;
}
