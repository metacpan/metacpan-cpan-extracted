/*
 * parse_desc_nvod_reference.c
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

#include "parse_desc_nvod_reference.h"
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
// NVOD_reference_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//   transport_stream_id  16 uimsbf
//   original_network_id  16 uimsbf
//   service_id  16 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_nvod_reference(struct Descriptor_nvod_reference *nrd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  nvod_reference [0x%02x]\n", nrd->descriptor_tag) ;
	printf("    Length: %d\n", nrd->descriptor_length) ;

	
	list_for_each_safe(item,safe,&nrd->nrd_array) {
		struct NRD_entry *nrd_entry = list_entry(item, struct NRD_entry, next);
		
		// NRD entry
		printf("      -NRD entry-\n") ;
		
		printf("      transport_stream_id = %d\n", nrd_entry->transport_stream_id) ;
		printf("      original_network_id = %d\n", nrd_entry->original_network_id) ;
		printf("      service_id = %d\n", nrd_entry->service_id) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_nvod_reference(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_nvod_reference *nrd ;
unsigned byte ;
int end_buff_len ;

	nrd = (struct Descriptor_nvod_reference *)malloc( sizeof(*nrd) ) ;
	memset(nrd,0,sizeof(*nrd));

	//== Parse data ==
	INIT_LIST_HEAD(&nrd->next);
	nrd->descriptor_tag = tag ; // already extracted by parse_desc()
	nrd->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&nrd->nrd_array) ;
	end_buff_len = bits_len_calc(bits, -nrd->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct NRD_entry *nrd_entry = malloc(sizeof(*nrd_entry));
		memset(nrd_entry,0,sizeof(*nrd_entry));
		list_add_tail(&nrd_entry->next,&nrd->nrd_array);

		nrd_entry->transport_stream_id = bits_get(bits, 16) ;
		nrd_entry->original_network_id = bits_get(bits, 16) ;
		nrd_entry->service_id = bits_get(bits, 16) ;
	}
	
	
	return (struct Descriptor *)nrd ;
}
	
/* ----------------------------------------------------------------------- */
void free_nvod_reference(struct Descriptor_nvod_reference *nrd)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&nrd->nrd_array) {
		struct NRD_entry *nrd_entry = list_entry(item, struct NRD_entry, next);
		free(nrd_entry) ;
	}
	
	
	free(nrd) ;
}
