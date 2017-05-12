/*
 * parse_desc_cell_list.c
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

#include "parse_desc_cell_list.h"
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
// cell_list_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   cell_id  16 uimsbf
//   cell_latitude  16 uimsbf
//   cell_longitude  16 uimsbf
//   cell_extent_of_latitude  12 uimsbf
//   cell_extent_of_longitude  12 uimsbf
//   subcell_info_loop_length  8 uimsbf
//   for (j=0;j<N;j++){
//    cell_id_extension  8 uimsbf
//    subcell_latitude  16 uimsbf
//    subcell_longitude  16 uimsbf
//    subcell_extent_of_latitude  12 uimsbf
//    subcell_extent_of_longitude  12 uimsbf
//     }
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_cell_list(struct Descriptor_cell_list *cld, int level)
{
struct list_head  *item, *safe;
struct list_head  *item1, *safe1;

	printf("    Descriptor:  cell_list [0x%02x]\n", cld->descriptor_tag) ;
	printf("    Length: %d\n", cld->descriptor_length) ;

	
	list_for_each_safe(item,safe,&cld->cld_array) {
		struct CLD_entry *cld_entry = list_entry(item, struct CLD_entry, next);
		
		// CLD entry
		printf("      -CLD entry-\n") ;
		
		printf("      cell_id = %d\n", cld_entry->cell_id) ;
		printf("      cell_latitude = %d\n", cld_entry->cell_latitude) ;
		printf("      cell_longitude = %d\n", cld_entry->cell_longitude) ;
		printf("      cell_extent_of_latitude = %d\n", cld_entry->cell_extent_of_latitude) ;
		printf("      cell_extent_of_longitude = %d\n", cld_entry->cell_extent_of_longitude) ;
		printf("      subcell_info_loop_length = %d\n", cld_entry->subcell_info_loop_length) ;
		
		list_for_each_safe(item1,safe1,&cld_entry->cld1_array) {
			struct CLD1_entry *cld1_entry = list_entry(item, struct CLD1_entry, next);
			
			// CLD entry
			printf("        -CLD entry-\n") ;
			
			printf("        cell_id_extension = %d\n", cld1_entry->cell_id_extension) ;
			printf("        subcell_latitude = %d\n", cld1_entry->subcell_latitude) ;
			printf("        subcell_longitude = %d\n", cld1_entry->subcell_longitude) ;
			printf("        subcell_extent_of_latitude = %d\n", cld1_entry->subcell_extent_of_latitude) ;
			printf("        subcell_extent_of_longitude = %d\n", cld1_entry->subcell_extent_of_longitude) ;
		}
		
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_cell_list(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_cell_list *cld ;
unsigned byte ;
int end_buff_len ;

	cld = (struct Descriptor_cell_list *)malloc( sizeof(*cld) ) ;
	memset(cld,0,sizeof(*cld));

	//== Parse data ==
	INIT_LIST_HEAD(&cld->next);
	cld->descriptor_tag = tag ; // already extracted by parse_desc()
	cld->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&cld->cld_array) ;
	end_buff_len = bits_len_calc(bits, -cld->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct CLD_entry *cld_entry = malloc(sizeof(*cld_entry));
		memset(cld_entry,0,sizeof(*cld_entry));
		list_add_tail(&cld_entry->next,&cld->cld_array);

		cld_entry->cell_id = bits_get(bits, 16) ;
		cld_entry->cell_latitude = bits_get(bits, 16) ;
		cld_entry->cell_longitude = bits_get(bits, 16) ;
		cld_entry->cell_extent_of_latitude = bits_get(bits, 12) ;
		cld_entry->cell_extent_of_longitude = bits_get(bits, 12) ;
		cld_entry->subcell_info_loop_length = bits_get(bits, 8) ;
		
		INIT_LIST_HEAD(&cld_entry->cld1_array) ;
		while (bits->buff_len >= 8)
		{
			struct CLD1_entry *cld1_entry = malloc(sizeof(*cld1_entry));
			memset(cld1_entry,0,sizeof(*cld1_entry));
			list_add_tail(&cld1_entry->next,&cld_entry->cld1_array);

			cld1_entry->cell_id_extension = bits_get(bits, 8) ;
			cld1_entry->subcell_latitude = bits_get(bits, 16) ;
			cld1_entry->subcell_longitude = bits_get(bits, 16) ;
			cld1_entry->subcell_extent_of_latitude = bits_get(bits, 12) ;
			cld1_entry->subcell_extent_of_longitude = bits_get(bits, 12) ;
		}
		
	}
	
	
	return (struct Descriptor *)cld ;
}
	
/* ----------------------------------------------------------------------- */
void free_cell_list(struct Descriptor_cell_list *cld)
{
struct list_head  *item, *safe;
struct list_head  *item1, *safe1;
	
	list_for_each_safe(item,safe,&cld->cld_array) {
		struct CLD_entry *cld_entry = list_entry(item, struct CLD_entry, next);
		
		list_for_each_safe(item1,safe1,&cld_entry->cld1_array) {
			struct CLD1_entry *cld1_entry = list_entry(item, struct CLD1_entry, next);
			free(cld1_entry) ;
		}
		
		free(cld_entry) ;
	}
	
	
	free(cld) ;
}
