/*
 * parse_desc_vbi_data.c
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

#include "parse_desc_vbi_data.h"
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
// VBI_data_descriptor() {
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0; i<N; i++) {
//   data_service_id  8 uimsbf
//   data_service_descriptor_length  8 uimsbf
//   if (data_service_id==0x01 ||
//       for (i=0; i<N; i++) {
//     reserved  2 bslbf
//     field_parity  1 bslbf
//     line_offset  5 uimsbf
//       }
//   } else {
//       for (i=0; i<N; i++) {
//     reserved  8 bslbf
//       }
//     }
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_vbi_data(struct Descriptor_vbi_data *vdd, int level)
{
struct list_head  *item, *safe;
struct list_head  *item1, *safe1;

	printf("    Descriptor:  vbi_data [0x%02x]\n", vdd->descriptor_tag) ;
	printf("    Length: %d\n", vdd->descriptor_length) ;

	
	list_for_each_safe(item,safe,&vdd->vdd_array) {
		struct VDD_entry *vdd_entry = list_entry(item, struct VDD_entry, next);
		
		// VDD entry
		printf("      -VDD entry-\n") ;
		
		printf("      data_service_id = %d\n", vdd_entry->data_service_id) ;
		printf("      data_service_descriptor_length = %d\n", vdd_entry->data_service_descriptor_length) ;
		if (vdd_entry->data_service_id == 0x1 || vdd_entry->data_service_id == 0x2 || vdd_entry->data_service_id == 0x4 || vdd_entry->data_service_id == 0x5 || vdd_entry->data_service_id == 0x6 || vdd_entry->data_service_id == 0x7  )
		{
		
		list_for_each_safe(item1,safe1,&vdd_entry->vdd1_array) {
			struct VDD1_entry *vdd1_entry = list_entry(item, struct VDD1_entry, next);
			
			// VDD entry
			printf("        -VDD entry-\n") ;
			
			printf("        field_parity = %d\n", vdd1_entry->field_parity) ;
			printf("        line_offset = %d\n", vdd1_entry->line_offset) ;
		}
		
		}
		else
		{
		bits_dump("data_service_descriptor", vdd_entry->data_service_descriptor, vdd_entry->data_service_descriptor_length, 3) ;
		}
		
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_vbi_data(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_vbi_data *vdd ;
unsigned byte ;
int end_buff_len ;

	vdd = (struct Descriptor_vbi_data *)malloc( sizeof(*vdd) ) ;
	memset(vdd,0,sizeof(*vdd));

	//== Parse data ==
	INIT_LIST_HEAD(&vdd->next);
	vdd->descriptor_tag = tag ; // already extracted by parse_desc()
	vdd->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&vdd->vdd_array) ;
	end_buff_len = bits_len_calc(bits, -vdd->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct VDD_entry *vdd_entry = malloc(sizeof(*vdd_entry));
		memset(vdd_entry,0,sizeof(*vdd_entry));
		list_add_tail(&vdd_entry->next,&vdd->vdd_array);

		vdd_entry->data_service_id = bits_get(bits, 8) ;
		vdd_entry->data_service_descriptor_length = bits_get(bits, 8) ;
		if (vdd_entry->data_service_id == 0x1 || vdd_entry->data_service_id == 0x2 || vdd_entry->data_service_id == 0x4 || vdd_entry->data_service_id == 0x5 || vdd_entry->data_service_id == 0x6 || vdd_entry->data_service_id == 0x7  )
		{
		
		INIT_LIST_HEAD(&vdd_entry->vdd1_array) ;
		while (bits->buff_len >= 1)
		{
			struct VDD1_entry *vdd1_entry = malloc(sizeof(*vdd1_entry));
			memset(vdd1_entry,0,sizeof(*vdd1_entry));
			list_add_tail(&vdd1_entry->next,&vdd_entry->vdd1_array);

			bits_skip(bits, 2) ;
			vdd1_entry->field_parity = bits_get(bits, 1) ;
			vdd1_entry->line_offset = bits_get(bits, 5) ;
		}
		
		}
		else
		{

		end_buff_len = bits_len_calc(bits, -vdd_entry->data_service_descriptor_length) ;
		vdd_entry->data_service_descriptor[0] = 0 ;
		for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_DATA_SERVICE_DESCRIPTOR_LEN); ++byte)
		{
			vdd_entry->data_service_descriptor[byte] = bits_get(bits, 8) ;
			vdd_entry->data_service_descriptor[byte+1] = 0 ;
		}

		}
		
	}
	
	
	return (struct Descriptor *)vdd ;
}
	
/* ----------------------------------------------------------------------- */
void free_vbi_data(struct Descriptor_vbi_data *vdd)
{
struct list_head  *item, *safe;
struct list_head  *item1, *safe1;
	
	list_for_each_safe(item,safe,&vdd->vdd_array) {
		struct VDD_entry *vdd_entry = list_entry(item, struct VDD_entry, next);
		
		list_for_each_safe(item1,safe1,&vdd_entry->vdd1_array) {
			struct VDD1_entry *vdd1_entry = list_entry(item, struct VDD1_entry, next);
			free(vdd1_entry) ;
		}
		
		free(vdd_entry) ;
	}
	
	
	free(vdd) ;
}
