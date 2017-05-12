/* GLOBAL.H - RSAREF types and constants
 */

/* PROTOTYPES should be set to one if and only if the compiler supports
  function argument prototyping.
The following makes PROTOTYPES default to 0 if it has not already
  been defined with C compiler flags.
 */
#ifndef PROTOTYPES
#define PROTOTYPES 0
#endif

/* POINTER defines a generic pointer type */
typedef unsigned char *POINTER;

/* UINT2 defines a two byte word */
typedef unsigned short int UINT2;

/* UINT4 defines a four byte word.
We use the Perl byte-order definition to discover if a long has more than
  4 bytes. If so we will try to use an unsigned int. This is OK for DEC
  Alpha but may not work everywhere. See the TO32 definition below.
 */
#if (PERL_BYTEORDER <= 4321) || defined(UINT4_IS_LONG)
typedef unsigned long UINT4;
#else
typedef unsigned int UINT4;
#endif

/* TO32 ensures that UINT4 values are truncated to 32 bits.
A Cray has short, int and long all at 64 bits so we need to apply this
  macro to reduce UINT4 values to 32 bits at appropriate places. If UINT4
  really does have 32 bits then this is a no-op.
 */
#if defined(cray) || defined(TRUNCATE_UINT4)
#define TO32(x)	((x) & 0xffffffff)
#else
#define TO32(x)	(x)
#endif

/* PROTO_LIST is defined depending on how PROTOTYPES is defined above.
If using PROTOTYPES, then PROTO_LIST returns the list, otherwise it
  returns an empty list.
 */
#if PROTOTYPES
#define PROTO_LIST(list) list
#else
#define PROTO_LIST(list) ()
#endif
