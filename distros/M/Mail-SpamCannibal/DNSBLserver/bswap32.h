/* bswap32.h
 *
 *	portable byteswap
 *
 *	version 1.00 9-23-03
 *
 */

/* (out) and (in) are u_char pointers	*/

#define bswap32(out,in) \
  *(out) = *((in) +3); \
  *((out) +1) = *((in) +2); \
  *((out) +2) = *((in) +1); \
  *((out) +3) = *(in)
