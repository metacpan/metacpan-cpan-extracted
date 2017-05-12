/*
 * parse_desc_service_list.c
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

#include "parse_desc_service_list.h"
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
// service_list_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;I++){
//   service_id  16 uimsbf
//   service_type  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_service_list(struct Descriptor_service_list *sld, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  service_list [0x%02x]\n", sld->descriptor_tag) ;
	printf("    Length: %d\n", sld->descriptor_length) ;

	
	list_for_each_safe(item,safe,&sld->sld_array) {
		struct SLD_entry *sld_entry = list_entry(item, struct SLD_entry, next);
		
		// SLD entry
		printf("      -SLD entry-\n") ;
		
		printf("      service_id = %d\n", sld_entry->service_id) ;
		printf("      service_type = %d\n", sld_entry->service_type) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_service_list(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_service_list *sld ;
unsigned byte ;
int end_buff_len ;

	sld = (struct Descriptor_service_list *)malloc( sizeof(*sld) ) ;
	memset(sld,0,sizeof(*sld));

	//== Parse data ==
	INIT_LIST_HEAD(&sld->next);
	sld->descriptor_tag = tag ; // already extracted by parse_desc()
	sld->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&sld->sld_array) ;
	end_buff_len = bits_len_calc(bits, -sld->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct SLD_entry *sld_entry = malloc(sizeof(*sld_entry));
		memset(sld_entry,0,sizeof(*sld_entry));
		list_add_tail(&sld_entry->next,&sld->sld_array);

		sld_entry->service_id = bits_get(bits, 16) ;
		sld_entry->service_type = bits_get(bits, 8) ;
	}
	
	
	return (struct Descriptor *)sld ;
}
	
/* ----------------------------------------------------------------------- */
void free_service_list(struct Descriptor_service_list *sld)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&sld->sld_array) {
		struct SLD_entry *sld_entry = list_entry(item, struct SLD_entry, next);
		free(sld_entry) ;
	}
	
	
	free(sld) ;
}
