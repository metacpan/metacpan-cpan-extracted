/*
 * parse_desc_transport_stream.c
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

#include "parse_desc_transport_stream.h"
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
// transport_stream_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   byte  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_transport_stream(struct Descriptor_transport_stream *tsd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  transport_stream [0x%02x]\n", tsd->descriptor_tag) ;
	printf("    Length: %d\n", tsd->descriptor_length) ;

	printf("    byte = \"%s\"\n", tsd->byte) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_transport_stream(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_transport_stream *tsd ;
unsigned byte ;
int end_buff_len ;

	tsd = (struct Descriptor_transport_stream *)malloc( sizeof(*tsd) ) ;
	memset(tsd,0,sizeof(*tsd));

	//== Parse data ==
	INIT_LIST_HEAD(&tsd->next);
	tsd->descriptor_tag = tag ; // already extracted by parse_desc()
	tsd->descriptor_length = len ; // already extracted by parse_desc()

	end_buff_len = bits_len_calc(bits, -tsd->descriptor_length) ;
	tsd->byte[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_BYTE_LEN); ++byte)
	{
		tsd->byte[byte] = bits_get(bits, 8) ;
		tsd->byte[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)tsd ;
}
	
/* ----------------------------------------------------------------------- */
void free_transport_stream(struct Descriptor_transport_stream *tsd)
{
struct list_head  *item, *safe;
	
	free(tsd) ;
}
