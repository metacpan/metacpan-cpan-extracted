/*
 * parse_desc_private_data_specifier.c
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

#include "parse_desc_private_data_specifier.h"
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
// private_data_specifier_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  private_data_specifier  32 uimsbf
// }

	
/* ----------------------------------------------------------------------- */
void print_private_data_specifier(struct Descriptor_private_data_specifier *pdsd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  private_data_specifier [0x%02x]\n", pdsd->descriptor_tag) ;
	printf("    Length: %d\n", pdsd->descriptor_length) ;

	printf("    private_data_specifier = %d\n", pdsd->private_data_specifier) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_private_data_specifier(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_private_data_specifier *pdsd ;
unsigned byte ;
int end_buff_len ;

	pdsd = (struct Descriptor_private_data_specifier *)malloc( sizeof(*pdsd) ) ;
	memset(pdsd,0,sizeof(*pdsd));

	//== Parse data ==
	INIT_LIST_HEAD(&pdsd->next);
	pdsd->descriptor_tag = tag ; // already extracted by parse_desc()
	pdsd->descriptor_length = len ; // already extracted by parse_desc()
	pdsd->private_data_specifier = bits_get(bits, 32) ;
	
	return (struct Descriptor *)pdsd ;
}
	
/* ----------------------------------------------------------------------- */
void free_private_data_specifier(struct Descriptor_private_data_specifier *pdsd)
{
struct list_head  *item, *safe;
	
	free(pdsd) ;
}
