/*
 * ts_bits.h
 *
 *  Created on: 2 Apr 2011
 *      Author: sdprice1
 */

#ifndef TS_BITS_H_
#define TS_BITS_H_

/*=============================================================================================*/
// USES
/*=============================================================================================*/
#include <time.h>

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

/*=============================================================================================*/
// MACROS
/*=============================================================================================*/

/*=============================================================================================*/
// STRUCTS
/*=============================================================================================*/

struct TS_bits {
	uint8_t *buff_ptr ;
	int buff_len ;
	unsigned start_bit ;
};

/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

void bits_free(struct TS_bits **bits);
struct TS_bits *bits_new(uint8_t *src, unsigned src_len);
unsigned bits_get(struct TS_bits *bits, unsigned len);
void bits_skip(struct TS_bits *bits, unsigned len);
int bits_len_calc(struct TS_bits *bits, int offset);
struct tm bits_get_mjd_time(struct TS_bits *bits) ;

// Utility print functions
void bits_dump_indent(unsigned level) ;
void bits_dump(char *name, unsigned *buff, unsigned length, unsigned level) ;


#endif /* TS_BITS_H_ */
