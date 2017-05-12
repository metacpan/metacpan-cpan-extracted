/*
 * parse_desc_cell_frequency_link.c
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

#include "parse_desc_cell_frequency_link.h"
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
// cell_frequency_link_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   cell_id  16 uimsbf
//   frequency  32 uimsbf
//   subcell_info_loop_length  8 uimsbf
//   for (j=0;j<N;j++){
//    cell_id_extension  8 uimsbf
//    transposer_frequency  32 uimsbf
//    }
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_cell_frequency_link(struct Descriptor_cell_frequency_link *cfld, int level)
{
struct list_head  *item, *safe;
struct list_head  *item1, *safe1;

	printf("    Descriptor:  cell_frequency_link [0x%02x]\n", cfld->descriptor_tag) ;
	printf("    Length: %d\n", cfld->descriptor_length) ;

	
	list_for_each_safe(item,safe,&cfld->cfld_array) {
		struct CFLD_entry *cfld_entry = list_entry(item, struct CFLD_entry, next);
		
		// CFLD entry
		printf("      -CFLD entry-\n") ;
		
		printf("      cell_id = %d\n", cfld_entry->cell_id) ;
		printf("      frequency = %d\n", cfld_entry->frequency) ;
		printf("      subcell_info_loop_length = %d\n", cfld_entry->subcell_info_loop_length) ;
		
		list_for_each_safe(item1,safe1,&cfld_entry->cfld1_array) {
			struct CFLD1_entry *cfld1_entry = list_entry(item, struct CFLD1_entry, next);
			
			// CFLD entry
			printf("        -CFLD entry-\n") ;
			
			printf("        cell_id_extension = %d\n", cfld1_entry->cell_id_extension) ;
			printf("        transposer_frequency = %d\n", cfld1_entry->transposer_frequency) ;
		}
		
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_cell_frequency_link(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_cell_frequency_link *cfld ;
unsigned byte ;
int end_buff_len ;

	cfld = (struct Descriptor_cell_frequency_link *)malloc( sizeof(*cfld) ) ;
	memset(cfld,0,sizeof(*cfld));

	//== Parse data ==
	INIT_LIST_HEAD(&cfld->next);
	cfld->descriptor_tag = tag ; // already extracted by parse_desc()
	cfld->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&cfld->cfld_array) ;
	end_buff_len = bits_len_calc(bits, -cfld->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct CFLD_entry *cfld_entry = malloc(sizeof(*cfld_entry));
		memset(cfld_entry,0,sizeof(*cfld_entry));
		list_add_tail(&cfld_entry->next,&cfld->cfld_array);

		cfld_entry->cell_id = bits_get(bits, 16) ;
		cfld_entry->frequency = bits_get(bits, 32) ;
		cfld_entry->subcell_info_loop_length = bits_get(bits, 8) ;
		
		INIT_LIST_HEAD(&cfld_entry->cfld1_array) ;
		while (bits->buff_len >= 5)
		{
			struct CFLD1_entry *cfld1_entry = malloc(sizeof(*cfld1_entry));
			memset(cfld1_entry,0,sizeof(*cfld1_entry));
			list_add_tail(&cfld1_entry->next,&cfld_entry->cfld1_array);

			cfld1_entry->cell_id_extension = bits_get(bits, 8) ;
			cfld1_entry->transposer_frequency = bits_get(bits, 32) ;
		}
		
	}
	
	
	return (struct Descriptor *)cfld ;
}
	
/* ----------------------------------------------------------------------- */
void free_cell_frequency_link(struct Descriptor_cell_frequency_link *cfld)
{
struct list_head  *item, *safe;
struct list_head  *item1, *safe1;
	
	list_for_each_safe(item,safe,&cfld->cfld_array) {
		struct CFLD_entry *cfld_entry = list_entry(item, struct CFLD_entry, next);
		
		list_for_each_safe(item1,safe1,&cfld_entry->cfld1_array) {
			struct CFLD1_entry *cfld1_entry = list_entry(item, struct CFLD1_entry, next);
			free(cfld1_entry) ;
		}
		
		free(cfld_entry) ;
	}
	
	
	free(cfld) ;
}
