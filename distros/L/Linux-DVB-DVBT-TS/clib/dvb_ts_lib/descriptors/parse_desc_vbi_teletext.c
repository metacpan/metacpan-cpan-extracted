/*
 * parse_desc_vbi_teletext.c
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

#include "parse_desc_vbi_teletext.h"
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
// VBI_teletext_descriptor() {
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//   ISO_639_language_code  24 bslbf
//   teletext_type  5 uimsbf
//  teletext_magazine_number  3 uimsbf
//   teletext_page_number  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_vbi_teletext(struct Descriptor_vbi_teletext *vtd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  vbi_teletext [0x%02x]\n", vtd->descriptor_tag) ;
	printf("    Length: %d\n", vtd->descriptor_length) ;

	
	list_for_each_safe(item,safe,&vtd->vtd_array) {
		struct VTD_entry *vtd_entry = list_entry(item, struct VTD_entry, next);
		
		// VTD entry
		printf("      -VTD entry-\n") ;
		
		printf("      ISO_639_language_code = %d\n", vtd_entry->ISO_639_language_code) ;
		printf("      teletext_type = %d\n", vtd_entry->teletext_type) ;
		printf("      teletext_magazine_number = %d\n", vtd_entry->teletext_magazine_number) ;
		printf("      teletext_page_number = %d\n", vtd_entry->teletext_page_number) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_vbi_teletext(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_vbi_teletext *vtd ;
unsigned byte ;
int end_buff_len ;

	vtd = (struct Descriptor_vbi_teletext *)malloc( sizeof(*vtd) ) ;
	memset(vtd,0,sizeof(*vtd));

	//== Parse data ==
	INIT_LIST_HEAD(&vtd->next);
	vtd->descriptor_tag = tag ; // already extracted by parse_desc()
	vtd->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&vtd->vtd_array) ;
	end_buff_len = bits_len_calc(bits, -vtd->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct VTD_entry *vtd_entry = malloc(sizeof(*vtd_entry));
		memset(vtd_entry,0,sizeof(*vtd_entry));
		list_add_tail(&vtd_entry->next,&vtd->vtd_array);

		vtd_entry->ISO_639_language_code = bits_get(bits, 24) ;
		vtd_entry->teletext_type = bits_get(bits, 5) ;
		vtd_entry->teletext_magazine_number = bits_get(bits, 3) ;
		vtd_entry->teletext_page_number = bits_get(bits, 8) ;
	}
	
	
	return (struct Descriptor *)vtd ;
}
	
/* ----------------------------------------------------------------------- */
void free_vbi_teletext(struct Descriptor_vbi_teletext *vtd)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&vtd->vtd_array) {
		struct VTD_entry *vtd_entry = list_entry(item, struct VTD_entry, next);
		free(vtd_entry) ;
	}
	
	
	free(vtd) ;
}
