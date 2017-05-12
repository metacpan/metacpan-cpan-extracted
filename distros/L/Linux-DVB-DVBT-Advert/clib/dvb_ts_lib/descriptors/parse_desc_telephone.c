/*
 * parse_desc_telephone.c
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

#include "parse_desc_telephone.h"
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
// telephone_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  reserved_future_use  2 bslbf
//  foreign_availability  1 bslbf
//  connection_type  5 uimsbf
//  reserved_future_use  1 bslbf
//  country_prefix_length  2 uimsbf
//  international_area_code_length  3 uimsbf
//  operator_code_length  2 uimsbf
//  reserved_future_use  1 bslbf
//  national_area_code_length  3 uimsbf
//  core_number_length  4 uimsbf
//  for (i=0;i<N;i++){
//   country_prefix_char  8 uimsbf
//  }
//  for (i=0;i<N;i++){
//   international_area_code_char  8 uimsbf
//  }
//  for (i=0;i<N;i++){
//   operator_code_char  8 uimsbf
//  }
//  for (i=0;i<N;i++){
//   national_area_code_char  8 uimsbf
//  }
//  for (i=0;i<N;i++){
//   core_number_char  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_telephone(struct Descriptor_telephone *td, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  telephone [0x%02x]\n", td->descriptor_tag) ;
	printf("    Length: %d\n", td->descriptor_length) ;

	printf("    foreign_availability = %d\n", td->foreign_availability) ;
	printf("    connection_type = %d\n", td->connection_type) ;
	printf("    country_prefix_length = %d\n", td->country_prefix_length) ;
	printf("    international_area_code_length = %d\n", td->international_area_code_length) ;
	printf("    operator_code_length = %d\n", td->operator_code_length) ;
	printf("    national_area_code_length = %d\n", td->national_area_code_length) ;
	printf("    core_number_length = %d\n", td->core_number_length) ;
	printf("    country_prefix = \"%s\"\n", td->country_prefix) ;
	printf("    international_area_code = \"%s\"\n", td->international_area_code) ;
	printf("    operator_code = \"%s\"\n", td->operator_code) ;
	printf("    national_area_code = \"%s\"\n", td->national_area_code) ;
	printf("    core_number = \"%s\"\n", td->core_number) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_telephone(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_telephone *td ;
unsigned byte ;
int end_buff_len ;

	td = (struct Descriptor_telephone *)malloc( sizeof(*td) ) ;
	memset(td,0,sizeof(*td));

	//== Parse data ==
	INIT_LIST_HEAD(&td->next);
	td->descriptor_tag = tag ; // already extracted by parse_desc()
	td->descriptor_length = len ; // already extracted by parse_desc()
	bits_skip(bits, 2) ;
	td->foreign_availability = bits_get(bits, 1) ;
	td->connection_type = bits_get(bits, 5) ;
	bits_skip(bits, 1) ;
	td->country_prefix_length = bits_get(bits, 2) ;
	td->international_area_code_length = bits_get(bits, 3) ;
	td->operator_code_length = bits_get(bits, 2) ;
	bits_skip(bits, 1) ;
	td->national_area_code_length = bits_get(bits, 3) ;
	td->core_number_length = bits_get(bits, 4) ;

	end_buff_len = bits_len_calc(bits, -td->country_prefix_length) ;
	td->country_prefix[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_COUNTRY_PREFIX_LEN); ++byte)
	{
		td->country_prefix[byte] = bits_get(bits, 8) ;
		td->country_prefix[byte+1] = 0 ;
	}


	end_buff_len = bits_len_calc(bits, -td->international_area_code_length) ;
	td->international_area_code[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_INTERNATIONAL_AREA_CODE_LEN); ++byte)
	{
		td->international_area_code[byte] = bits_get(bits, 8) ;
		td->international_area_code[byte+1] = 0 ;
	}


	end_buff_len = bits_len_calc(bits, -td->operator_code_length) ;
	td->operator_code[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_OPERATOR_CODE_LEN); ++byte)
	{
		td->operator_code[byte] = bits_get(bits, 8) ;
		td->operator_code[byte+1] = 0 ;
	}


	end_buff_len = bits_len_calc(bits, -td->national_area_code_length) ;
	td->national_area_code[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_NATIONAL_AREA_CODE_LEN); ++byte)
	{
		td->national_area_code[byte] = bits_get(bits, 8) ;
		td->national_area_code[byte+1] = 0 ;
	}


	end_buff_len = bits_len_calc(bits, -td->core_number_length) ;
	td->core_number[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_CORE_NUMBER_LEN); ++byte)
	{
		td->core_number[byte] = bits_get(bits, 8) ;
		td->core_number[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)td ;
}
	
/* ----------------------------------------------------------------------- */
void free_telephone(struct Descriptor_telephone *td)
{
struct list_head  *item, *safe;
	
	free(td) ;
}
