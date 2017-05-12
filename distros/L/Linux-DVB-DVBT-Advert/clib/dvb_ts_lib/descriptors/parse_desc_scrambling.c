/*
 * parse_desc_scrambling.c
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

#include "parse_desc_scrambling.h"
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
// scrambling_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  scrambling_mode  8 uimsbf
// }

	
/* ----------------------------------------------------------------------- */
void print_scrambling(struct Descriptor_scrambling *sd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  scrambling [0x%02x]\n", sd->descriptor_tag) ;
	printf("    Length: %d\n", sd->descriptor_length) ;

	printf("    scrambling_mode = %d\n", sd->scrambling_mode) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_scrambling(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_scrambling *sd ;
unsigned byte ;
int end_buff_len ;

	sd = (struct Descriptor_scrambling *)malloc( sizeof(*sd) ) ;
	memset(sd,0,sizeof(*sd));

	//== Parse data ==
	INIT_LIST_HEAD(&sd->next);
	sd->descriptor_tag = tag ; // already extracted by parse_desc()
	sd->descriptor_length = len ; // already extracted by parse_desc()
	sd->scrambling_mode = bits_get(bits, 8) ;
	
	return (struct Descriptor *)sd ;
}
	
/* ----------------------------------------------------------------------- */
void free_scrambling(struct Descriptor_scrambling *sd)
{
struct list_head  *item, *safe;
	
	free(sd) ;
}
