/*
 * parse_desc_tva_content_identifier.c
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

#include "parse_desc_tva_content_identifier.h"
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
// TVA_content_identifier_descriptor() {
// descriptor_tag 8 uimsbf
// descriptor_length 8 uimsbf
// for (i=0;i<N;i++) {
// crid_type 6 uimsbf
// crid_location 2 uimsbf
// if (crid_location == '00' ) {
// crid_length 8 uimsbf
// for (j=0;j<crid_length;j++) {
// crid_byte 8 uimsbf
// }
// }
// if (crid_location == '01' ) {
// crid_ref 16 uimsbf
// }
// }
// }

	
/* ----------------------------------------------------------------------- */
void print_tva_content_identifier(struct Descriptor_tva_content_identifier *tcid, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  tva_content_identifier [0x%02x]\n", tcid->descriptor_tag) ;
	printf("    Length: %d\n", tcid->descriptor_length) ;

	
	list_for_each_safe(item,safe,&tcid->tcid_array) {
		struct TCID_entry *tcid_entry = list_entry(item, struct TCID_entry, next);
		
		// TCID entry
		printf("      -TCID entry-\n") ;
		
		printf("      crid_type = %d\n", tcid_entry->crid_type) ;
		printf("      crid_location = %d\n", tcid_entry->crid_location) ;
		if (tcid_entry->crid_location == 0x0  )
		{
		printf("      crid_length = %d\n", tcid_entry->crid_length) ;
		printf("      crid = \"%s\"\n", tcid_entry->crid) ;
		}
		
		if (tcid_entry->crid_location == 0x1  )
		{
		printf("      crid_ref = %d\n", tcid_entry->crid_ref) ;
		}
		
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_tva_content_identifier(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_tva_content_identifier *tcid ;
unsigned byte ;
int end_buff_len ;

	tcid = (struct Descriptor_tva_content_identifier *)malloc( sizeof(*tcid) ) ;
	memset(tcid,0,sizeof(*tcid));

	//== Parse data ==
	INIT_LIST_HEAD(&tcid->next);
	tcid->descriptor_tag = tag ; // already extracted by parse_desc()
	tcid->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&tcid->tcid_array) ;
	end_buff_len = bits_len_calc(bits, -tcid->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct TCID_entry *tcid_entry = malloc(sizeof(*tcid_entry));
		memset(tcid_entry,0,sizeof(*tcid_entry));
		list_add_tail(&tcid_entry->next,&tcid->tcid_array);

		tcid_entry->crid_type = bits_get(bits, 6) ;
		tcid_entry->crid_location = bits_get(bits, 2) ;
		if (tcid_entry->crid_location == 0x0  )
		{
		tcid_entry->crid_length = bits_get(bits, 8) ;

		end_buff_len = bits_len_calc(bits, -tcid_entry->crid_length) ;
		tcid_entry->crid[0] = 0 ;
		for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_CRID_LEN); ++byte)
		{
			tcid_entry->crid[byte] = bits_get(bits, 8) ;
			tcid_entry->crid[byte+1] = 0 ;
		}

		}
		
		if (tcid_entry->crid_location == 0x1  )
		{
		tcid_entry->crid_ref = bits_get(bits, 16) ;
		}
		
	}
	
	
	return (struct Descriptor *)tcid ;
}
	
/* ----------------------------------------------------------------------- */
void free_tva_content_identifier(struct Descriptor_tva_content_identifier *tcid)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&tcid->tcid_array) {
		struct TCID_entry *tcid_entry = list_entry(item, struct TCID_entry, next);
		free(tcid_entry) ;
	}
	
	
	free(tcid) ;
}
