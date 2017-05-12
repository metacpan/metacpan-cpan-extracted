
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "clib/FastGF2.h"

#include "perlsubs.c"

MODULE = Math::FastGF2		PACKAGE = Math::FastGF2		

PROTOTYPES: ENABLE

gf2_u32
gf2_mul (width, a, b)
	int	width
	gf2_u32	a
	gf2_u32	b

gf2_u32
gf2_inv (width, a)
	int	width
	gf2_u32	a

gf2_u32
gf2_div (width, a, b)
	int	width
	gf2_u32	a
	gf2_u32	b

gf2_u32
gf2_pow (width, a, b)
	int	width
	gf2_u32	a
	gf2_u32	b

gf2_u32
gf2_info (bits)
	int bits


MODULE = Math::FastGF2     PACKAGE = Math::FastGF2::Matrix     PREFIX = mat_

PROTOTYPES: ENABLE

# Routines with a _c suffix should only be called internally by the
# Matrix class methods.

SV* 
mat_alloc_c (class, rows, cols, width, org)
  char* class
  int rows
  int cols
  int width
  int org

void
mat_DESTROY (self)
  SV* self

# Accessors get info about current Math::FastGF2::Matrix instance

int
mat_ROWS (self)
  SV* self

int
mat_COLS (self)
  SV* self

int
mat_WIDTH (self)
  SV* self

int
mat_ORGNUM (self)
  SV* self

gf2_u32
mat_getval (self, row, col) 
  SV* self
  int row
  int col

gf2_u32
mat_setval(self, row, col, val)
  SV *self
  int row
  int col
  gf2_u32 val

void
mat_multiply_submatrix_c (S, T, R, sr, rr, nr, xc, rc, nc)
  SV *S
  SV *T
  SV *R
  int sr
  int rr
  int nr
  int xc
  int rc
  int nc

int
mat_values_eq_c (This, That) 
  SV *This
  SV *That

SV*
mat_get_raw_values_c (Self, row, col, words, byteorder)
  SV *Self
  int row
  int col
  int words
  int byteorder

void
mat_set_raw_values_c (Self, row, col, words, byteorder, Str) 
  SV *Self
  int row
  int col
  int words
  int byteorder
  SV *Str

MODULE = Math::FastGF2  PACKAGE = Math::FastGF2::Matrix::FillSub  PREFIX = cbk__

PROTOTYPES: ENABLE

