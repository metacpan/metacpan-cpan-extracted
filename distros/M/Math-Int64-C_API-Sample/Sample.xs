
/* #define PERL_NO_GET_CONTEXT 1 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* define int64_t and uint64_t when using MinGW compiler */
#ifdef __MINGW32__
#include <stdint.h>
#endif

/* define int64_t and uint64_t when using MS compiler */
#ifdef _MSC_VER
#include <stdlib.h>
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#endif

/* uncomment the following line to use native IVs if they are 64bits long */
/* #define MATH_INT64_NATIVE_IF_AVAILABLE */

#include "perl_math_int64.h"

MODULE = Math::Int64::C_API::Sample		PACKAGE = Math::Int64::C_API::Sample		

PROTOTYPES: DISABLE

BOOT:
  PERL_MATH_INT64_LOAD_OR_CROAK;

int64_t
some_int64()
CODE:
    RETVAL = -42;
OUTPUT:
    RETVAL

uint64_t
uint64_sqr(u64)
    uint64_t u64
CODE:
    RETVAL = u64 * u64;
OUTPUT:
    RETVAL

int64_t
int64_addmul(acu, mul1, mul2)
    int64_t acu
    int64_t mul1
    int64_t mul2
CODE:
    RETVAL = acu + mul1 * mul2;
OUTPUT:
    RETVAL

uint64_t
uint64_rand()
CODE:
    RETVAL = randU64();
OUTPUT:
    RETVAL

void
sv_seti64(SV *sv, int64_t i64)

void
sv_setu64(SV *sv, uint64_t u64)
