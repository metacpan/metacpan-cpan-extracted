
/* This file is part of an implementation of the "grisu3" double to string
	conversion algorithm described in the research paper

	"Printing Floating-Point Numbers Quickly And Accurately with Integers"
	by Florian Loitsch, available at
	http://www.cs.tufts.edu/~nr/cs257/archive/florian-loitsch/printf.pdf */

#include <inttypes.h>
#include <assert.h> /* assert */

#ifdef _MSC_VER
#pragma warning(disable : 4204) /* nonstandard extension used : non-constant aggregate initializer */
#endif

#define D64_SIGN         0x8000000000000000ULL
#define D64_EXP_MASK     0x7FF0000000000000ULL
#define D64_FRACT_MASK   0x000FFFFFFFFFFFFFULL
#define D64_IMPLICIT_ONE 0x0010000000000000ULL
#define D64_EXP_POS      52
#define D64_EXP_BIAS     1075
#define DIYFP_FRACT_SIZE 64
#define D_1_LOG2_10      0.30102999566398114 /* 1 / lg(10) */
#define MIN_TARGET_EXP   -60
#define MASK32           0xFFFFFFFFULL

#define CAST_U64(d) (*(uint64_t*)&d)
#define GRISU3_MIN(x,y) ((x) <= (y) ? (x) : (y))
#define GRISU3_MAX(x,y) ((x) >= (y) ? (x) : (y))

#define MIN_CACHED_EXP -348
#define CACHED_EXP_STEP 8

typedef struct diy_fp {
  uint64_t f;
  int e;
} diy_fp;

typedef struct power {
  uint64_t fract;
  int16_t b_exp, d_exp;
} power;

