/*
 * parse_desc_local_time_offset.c
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

#include "parse_desc_local_time_offset.h"
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
// local_time_offset_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  for(i=0;i<N;i++){
//   country_code   24 bslbf
//   country_region_id  6 bslbf
//   reserved  1 bslbf
//   local_time_offset_polarity  1 bslbf
//   local_time_offset  16 bslbf
//   time_of_change  40 bslbf
//   next_time_offset  16 bslbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_local_time_offset(struct Descriptor_local_time_offset *ltod, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  local_time_offset [0x%02x]\n", ltod->descriptor_tag) ;
	printf("    Length: %d\n", ltod->descriptor_length) ;

	
	list_for_each_safe(item,safe,&ltod->ltod_array) {
		struct LTOD_entry *ltod_entry = list_entry(item, struct LTOD_entry, next);
		
		// LTOD entry
		printf("      -LTOD entry-\n") ;
		
		printf("      country_code = %d\n", ltod_entry->country_code) ;
		printf("      country_region_id = %d\n", ltod_entry->country_region_id) ;
		printf("      local_time_offset_polarity = %d\n", ltod_entry->local_time_offset_polarity) ;
		printf("      local_time_offset = %d\n", ltod_entry->local_time_offset) ;
		printf("      time_of_change = %02d-%02d-%04d %02d:%02d:%02d\n", 
		    ltod_entry->time_of_change.tm_mday, ltod_entry->time_of_change.tm_mon, ltod_entry->time_of_change.tm_year,
		    ltod_entry->time_of_change.tm_hour, ltod_entry->time_of_change.tm_min, ltod_entry->time_of_change.tm_sec
		) ;
		printf("      next_time_offset = %d\n", ltod_entry->next_time_offset) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_local_time_offset(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_local_time_offset *ltod ;
unsigned byte ;
int end_buff_len ;

	ltod = (struct Descriptor_local_time_offset *)malloc( sizeof(*ltod) ) ;
	memset(ltod,0,sizeof(*ltod));

	//== Parse data ==
	INIT_LIST_HEAD(&ltod->next);
	ltod->descriptor_tag = tag ; // already extracted by parse_desc()
	ltod->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&ltod->ltod_array) ;
	end_buff_len = bits_len_calc(bits, -ltod->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct LTOD_entry *ltod_entry = malloc(sizeof(*ltod_entry));
		memset(ltod_entry,0,sizeof(*ltod_entry));
		list_add_tail(&ltod_entry->next,&ltod->ltod_array);

		ltod_entry->country_code = bits_get(bits, 24) ;
		ltod_entry->country_region_id = bits_get(bits, 6) ;
		bits_skip(bits, 1) ;
		ltod_entry->local_time_offset_polarity = bits_get(bits, 1) ;
		ltod_entry->local_time_offset = bits_get(bits, 16) ;
		ltod_entry->time_of_change = bits_get_mjd_time(bits) ;
		ltod_entry->next_time_offset = bits_get(bits, 16) ;
	}
	
	
	return (struct Descriptor *)ltod ;
}
	
/* ----------------------------------------------------------------------- */
void free_local_time_offset(struct Descriptor_local_time_offset *ltod)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&ltod->ltod_array) {
		struct LTOD_entry *ltod_entry = list_entry(item, struct LTOD_entry, next);
		free(ltod_entry) ;
	}
	
	
	free(ltod) ;
}
