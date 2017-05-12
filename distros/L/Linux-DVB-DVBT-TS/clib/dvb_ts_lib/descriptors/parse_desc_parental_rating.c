/*
 * parse_desc_parental_rating.c
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

#include "parse_desc_parental_rating.h"
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
// parental_rating_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   country_code  24 bslbf
//   rating  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_parental_rating(struct Descriptor_parental_rating *prd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  parental_rating [0x%02x]\n", prd->descriptor_tag) ;
	printf("    Length: %d\n", prd->descriptor_length) ;

	
	list_for_each_safe(item,safe,&prd->prd_array) {
		struct PRD_entry *prd_entry = list_entry(item, struct PRD_entry, next);
		
		// PRD entry
		printf("      -PRD entry-\n") ;
		
		printf("      country_code = %d\n", prd_entry->country_code) ;
		printf("      rating = %d\n", prd_entry->rating) ;
	}
	
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_parental_rating(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_parental_rating *prd ;
unsigned byte ;
int end_buff_len ;

	prd = (struct Descriptor_parental_rating *)malloc( sizeof(*prd) ) ;
	memset(prd,0,sizeof(*prd));

	//== Parse data ==
	INIT_LIST_HEAD(&prd->next);
	prd->descriptor_tag = tag ; // already extracted by parse_desc()
	prd->descriptor_length = len ; // already extracted by parse_desc()
	
	INIT_LIST_HEAD(&prd->prd_array) ;
	end_buff_len = bits_len_calc(bits, -prd->descriptor_length ) ;
	while (bits->buff_len > end_buff_len)
	{
		struct PRD_entry *prd_entry = malloc(sizeof(*prd_entry));
		memset(prd_entry,0,sizeof(*prd_entry));
		list_add_tail(&prd_entry->next,&prd->prd_array);

		prd_entry->country_code = bits_get(bits, 24) ;
		prd_entry->rating = bits_get(bits, 8) ;
	}
	
	
	return (struct Descriptor *)prd ;
}
	
/* ----------------------------------------------------------------------- */
void free_parental_rating(struct Descriptor_parental_rating *prd)
{
struct list_head  *item, *safe;
	
	list_for_each_safe(item,safe,&prd->prd_array) {
		struct PRD_entry *prd_entry = list_entry(item, struct PRD_entry, next);
		free(prd_entry) ;
	}
	
	
	free(prd) ;
}
