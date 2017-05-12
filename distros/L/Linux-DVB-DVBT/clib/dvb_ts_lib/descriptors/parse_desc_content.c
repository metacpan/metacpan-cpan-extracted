/*
 * parse_desc_content.c
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

#include "parse_desc_content.h"
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
// content_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//    content_nibble_level_1  4 uimsbf
//    content_nibble_level_2  4 uimsbf
//    user_nibble  4 uimsbf
//    user_nibble  4 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_content(struct Descriptor_content *cd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  content [0x%02x]\n", cd->descriptor_tag) ;
	printf("    Length: %d\n", cd->descriptor_length) ;

	
	list_for_each_safe(item,safe,&cd->cd_array) {
		struct CD_entry *cd_entry = list_entry(item, struct CD_entry, next);
		
		// CD entry
		printf("      -CD entry-\n") ;
		
		printf("      content_nibble_level_1 = %d\n", cd_entry->content_nibble_level_1) ;
		printf("      content_nibble_level_2 = %d\n", cd_entry->content_nibble_level_2) ;
		printf("      user_nibble = %d\n", cd_entry->user_nibble) ;
		printf("      user_nibble1 = %d\n", cd_entry->user_nibble1) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_content(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_content *cd ;
unsigned byte ;
int end_buff_len ;

	cd = (struct Descriptor_content *)malloc( sizeof(*cd) ) ;
	memset(cd,0,sizeof(*cd));

	//== Parse data ==
	INIT_LIST_HEAD(&cd->next);
	cd->descriptor_tag = tag ; // already extracted by parse_desc()
	cd->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&cd->cd_array) ;
	end_buff_len = bits_len_calc(bits, -cd->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct CD_entry *cd_entry = malloc(sizeof(*cd_entry));
		memset(cd_entry,0,sizeof(*cd_entry));
		list_add_tail(&cd_entry->next,&cd->cd_array);

		cd_entry->content_nibble_level_1 = bits_get(bits, 4) ;
		cd_entry->content_nibble_level_2 = bits_get(bits, 4) ;
		cd_entry->user_nibble = bits_get(bits, 4) ;
		cd_entry->user_nibble1 = bits_get(bits, 4) ;
	}
	
	
	return (struct Descriptor *)cd ;
}
	
/* ----------------------------------------------------------------------- */
void free_content(struct Descriptor_content *cd)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&cd->cd_array) {
		struct CD_entry *cd_entry = list_entry(item, struct CD_entry, next);
		free(cd_entry) ;
	}
	
	
	free(cd) ;
}
