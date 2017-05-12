/* Fast GF(2^m) library routines */
/*
  Copyright (c) by Declan Malone 2009.
  Licensed under the terms of the GNU General Public License and
  the GNU Lesser (Library) General Public License.
*/

/*
  Typedefs may need to be changed to suit the word sizes on your
  particular platform. The main Makefile.PL should be able to guess
  these and pass the appropriate -DDEFINES (see below), but if not,
  you can use define USE_CUSTOM_TYPEDEFS and supply your own types.
*/

#ifdef USE_CUSTOM_TYPEDEFS

/*
  If you have a modern compiler that supports C99, you can include
  this next library to get access to u?int_(16|32) types:

#include <stdint.h>
*/

/* Put in your custom typedefs here. Here are some example values */
typedef unsigned char    gf2_u8;
typedef signed char      gf2_s8;
typedef unsigned short   gf2_u16;
typedef signed short     gf2_s16;
typedef unsigned long    gf2_u32;
typedef signed long      gf2_s32;

#else

/*
  Or else rely on the main Makefile.PL to define two of the following
  (ie, one from each column):

    SHORT_HAS_16_BITS          SHORT_HAS_32_BITS	  
    INT_HAS_16_BITS	       INT_HAS_32_BITS	  
    LONG_HAS_16_BITS  	       LONG_HAS_32_BITS	  
    LONG_LONG_HAS_16_BITS      LONG_LONG_HAS_32_BITS   
*/

/* These should be the same everywhere */
typedef unsigned char    gf2_u8;
typedef signed char      gf2_s8;

/*
  But these may need to be tailored to this machine. Exactly one of
  these must exist for each word size or else the compilation will
  fail with messages about undeclared types.
*/
#ifdef SHORT_HAS_16_BITS
typedef unsigned short      gf2_u16;
typedef signed short        gf2_s16;
#endif
#ifdef INT_HAS_16_BITS
typedef unsigned int        gf2_u16;
typedef signed int          gf2_s16;
#endif
#ifdef LONG_HAS_16_BITS
typedef unsigned long       gf2_u16;
typedef signed long         gf2_s16;
#endif
#ifdef LONGLONG_HAS_16_BITS
typedef unsigned long long  gf2_u16;
typedef signed long long    gf2_s16;
#endif
#ifdef SHORT_HAS_32_BITS
typedef unsigned short      gf2_u32;
typedef signed short        gf2_s32;
#endif
#ifdef INT_HAS_32_BITS
typedef unsigned int        gf2_u32;
typedef signed int          gf2_s32;
#endif
#ifdef LONG_HAS_32_BITS
typedef unsigned long       gf2_u32;
typedef signed long         gf2_s32;
#endif
#ifdef LONGLONG_HAS_32_BITS
typedef unsigned long long  gf2_u32;
typedef signed long long    gf2_s32;
#endif

#endif

/* Public interface routines */

/* basic maths */
gf2_u32 gf2_mul (int width, gf2_u32 a, gf2_u32 b);
gf2_u32 gf2_inv (int width, gf2_u32 a);
gf2_u32 gf2_div (int width, gf2_u32 a, gf2_u32 b);
gf2_u32 gf2_info(int bits);

/* matrix */
typedef struct {
  int rows;
  int cols;
  int width;			/* number of bytes in each element */
  char *values;
  enum {
    UNDEFINED, ROWWISE, COLWISE,
  } organisation;
  /* 
    save some information so we know whether to call free() when we're
    finished with the object. FREE_NONE means don't call free on either
    the structure or the values array.
  */
  enum {
    FREE_NONE, FREE_VALUES, FREE_STRUCT, FREE_BOTH,
  } alloc_bits;
} gf2_matrix_t;


int gf2_matrix_offset_right (gf2_matrix_t *m);
int gf2_matrix_offset_down (gf2_matrix_t *m);

#ifdef NOW_IS_OK

/* disabled code... mostly this is now implemented in Perl */

#ifdef _LARGEFILE64_SOURCE
#define OFF_T off64_t
#define OFF_T_FMT "%lld"
#define SEEK lseek64
#else
#define OFF_T off_t
#define OFF_T_FMT "%ld"
#define SEEK lseek
#endif

struct gf2_matrix_closure;	/* forward declaration needed */
typedef struct gf2_matrix_closure* gf2_matrix_closure_t;
typedef OFF_T 
  (*gf2_matrix_callback) (gf2_matrix_closure_t, char *, OFF_T);
union  gf2_polymorphic {
  char        c;
  int         i;
  long        l;
  OFF_T     L;
  float       f;
  double      d;
  long double D;
  int*        I;
  char*       C;
  void*       V;
  gf2_matrix_closure_t S;	/* S for 'S'truct */
  /* for other pointer types, simply use a cast */
};
struct gf2_matrix_closure {
  gf2_matrix_callback fp;       /* function callback */

  char  u1_type;		/* must match names in union below */
  int   u1_many;		/* for pointer types, how many? */
  union gf2_polymorphic u1;

  char  u2_type;		/* must match names in union below */
  int   u2_many;		/* for pointer types, how many? */
  union gf2_polymorphic u2;
};

/* streambuf control wraps up a closure and buffer-management data */
struct gf2_streambuf_control {
  struct gf2_matrix_closure handler;
  union {
    int  iwcol;
    int  orcol;
  } hc;
  OFF_T BF;
  union {
    char* IW;
    char* OR;
  } hp;
  char    *END;
  union {
    size_t max_safe_fill;
    size_t max_safe_empty;
  } hs;
};

int gf2_matrix_row_size_in_bytes (gf2_matrix_t *m);
int gf2_matrix_col_size_in_bytes (gf2_matrix_t *m);
char* gf2_matrix_element (gf2_matrix_t *m, int r, int c);
gf2_matrix_t* gf2_matrix_invert(gf2_matrix_t *m);
int gf2_matrix_multiply (gf2_matrix_t* result, char org, char* poly,
			 gf2_matrix_t* a, gf2_matrix_t* b);
#endif
