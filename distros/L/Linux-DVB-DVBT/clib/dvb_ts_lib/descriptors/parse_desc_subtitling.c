/*
 * parse_desc_subtitling.c
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

#include "parse_desc_subtitling.h"
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
// subtitling_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i= 0;i<N;I++){
//   ISO_639_language_code  24 bslbf
//   subtitling_type  8 bslbf
//   composition_page_id  16 bslbf
//   ancillary_page_id  16 bslbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_subtitling(struct Descriptor_subtitling *sd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  subtitling [0x%02x]\n", sd->descriptor_tag) ;
	printf("    Length: %d\n", sd->descriptor_length) ;

	
	list_for_each_safe(item,safe,&sd->sd_array) {
		struct SD_entry *sd_entry = list_entry(item, struct SD_entry, next);
		
		// SD entry
		printf("      -SD entry-\n") ;
		
		printf("      ISO_639_language_code = %d\n", sd_entry->ISO_639_language_code) ;
		printf("      subtitling_type = %d\n", sd_entry->subtitling_type) ;
		printf("      composition_page_id = %d\n", sd_entry->composition_page_id) ;
		printf("      ancillary_page_id = %d\n", sd_entry->ancillary_page_id) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_subtitling(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_subtitling *sd ;
unsigned byte ;
int end_buff_len ;

	sd = (struct Descriptor_subtitling *)malloc( sizeof(*sd) ) ;
	memset(sd,0,sizeof(*sd));

	//== Parse data ==
	INIT_LIST_HEAD(&sd->next);
	sd->descriptor_tag = tag ; // already extracted by parse_desc()
	sd->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&sd->sd_array) ;
	end_buff_len = bits_len_calc(bits, -sd->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct SD_entry *sd_entry = malloc(sizeof(*sd_entry));
		memset(sd_entry,0,sizeof(*sd_entry));
		list_add_tail(&sd_entry->next,&sd->sd_array);

		sd_entry->ISO_639_language_code = bits_get(bits, 24) ;
		sd_entry->subtitling_type = bits_get(bits, 8) ;
		sd_entry->composition_page_id = bits_get(bits, 16) ;
		sd_entry->ancillary_page_id = bits_get(bits, 16) ;
	}
	
	
	return (struct Descriptor *)sd ;
}
	
/* ----------------------------------------------------------------------- */
void free_subtitling(struct Descriptor_subtitling *sd)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&sd->sd_array) {
		struct SD_entry *sd_entry = list_entry(item, struct SD_entry, next);
		free(sd_entry) ;
	}
	
	
	free(sd) ;
}
