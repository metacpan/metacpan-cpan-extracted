/*
 * parse_desc_teletext.c
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

#include "parse_desc_teletext.h"
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
// teletext_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   ISO_639_language_code  24 bslbf
//   teletext_type  5 uimsbf
//   teletext_magazine_number  3 uimsbf
//   teletext_page_number  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_teletext(struct Descriptor_teletext *td, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  teletext [0x%02x]\n", td->descriptor_tag) ;
	printf("    Length: %d\n", td->descriptor_length) ;

	
	list_for_each_safe(item,safe,&td->td_array) {
		struct TD_entry *td_entry = list_entry(item, struct TD_entry, next);
		
		// TD entry
		printf("      -TD entry-\n") ;
		
		printf("      ISO_639_language_code = %d\n", td_entry->ISO_639_language_code) ;
		printf("      teletext_type = %d\n", td_entry->teletext_type) ;
		printf("      teletext_magazine_number = %d\n", td_entry->teletext_magazine_number) ;
		printf("      teletext_page_number = %d\n", td_entry->teletext_page_number) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_teletext(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_teletext *td ;
unsigned byte ;
int end_buff_len ;

	td = (struct Descriptor_teletext *)malloc( sizeof(*td) ) ;
	memset(td,0,sizeof(*td));

	//== Parse data ==
	INIT_LIST_HEAD(&td->next);
	td->descriptor_tag = tag ; // already extracted by parse_desc()
	td->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&td->td_array) ;
	end_buff_len = bits_len_calc(bits, -td->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct TD_entry *td_entry = malloc(sizeof(*td_entry));
		memset(td_entry,0,sizeof(*td_entry));
		list_add_tail(&td_entry->next,&td->td_array);

		td_entry->ISO_639_language_code = bits_get(bits, 24) ;
		td_entry->teletext_type = bits_get(bits, 5) ;
		td_entry->teletext_magazine_number = bits_get(bits, 3) ;
		td_entry->teletext_page_number = bits_get(bits, 8) ;
	}
	
	
	return (struct Descriptor *)td ;
}
	
/* ----------------------------------------------------------------------- */
void free_teletext(struct Descriptor_teletext *td)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&td->td_array) {
		struct TD_entry *td_entry = list_entry(item, struct TD_entry, next);
		free(td_entry) ;
	}
	
	
	free(td) ;
}
