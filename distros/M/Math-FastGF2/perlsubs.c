/* Fast GF(2^m) library routines */
/*
  Copyright (c) by Declan Malone 2009.
  Licensed under the terms of the GNU General Public License and
  the GNU Lesser (Library) General Public License.
*/


SV* mat_alloc_c(char* class, int rows, int cols, int width, int org) {

  gf2_matrix_t*  Matrix;
  SV*            obj_ref;
  SV*            obj;
 
  Matrix=malloc(sizeof (gf2_matrix_t));

  if (Matrix == NULL)  return &PL_sv_undef;

  Matrix->values=malloc(rows * cols * width);
  if (Matrix->values == NULL) { free(Matrix); return NULL; }
  memset(Matrix->values,0,rows * cols * width);

  Matrix->alloc_bits   = FREE_BOTH;
  Matrix->rows         = rows;
  Matrix->cols         = cols;
  Matrix->width        = width;
  Matrix->organisation = org;
 
  obj_ref = newSViv(0);		    
  obj     = newSVrv(obj_ref, class);

  sv_setiv(obj,(IV)Matrix);
  SvREADONLY_on(obj);
  return obj_ref;
}

void mat_DESTROY (SV* Self) {
  gf2_matrix_t *m=(gf2_matrix_t*)SvIV(SvRV(Self));
  if (m->alloc_bits & 1)
    free(m->values);
  if (m->alloc_bits & 2)
    free(m);
}

/* accessor methods; get info on ROWS, COLS, etc. */
int mat_ROWS (SV* Self) {
  return ((gf2_matrix_t*)SvIV(SvRV(Self)))->rows;
}

int mat_COLS (SV* Self) {
  return ((gf2_matrix_t*)SvIV(SvRV(Self)))->cols;
}

int mat_WIDTH (SV* Self) {
  return ((gf2_matrix_t*)SvIV(SvRV(Self)))->width;
}

int mat_ORGNUM  (SV* Self) {
  return ((gf2_matrix_t*)SvIV(SvRV(Self)))->organisation;
}

gf2_u32 mat_getval(SV *Self, int row, int col) {
  gf2_matrix_t *m=(gf2_matrix_t*)SvIV(SvRV(Self));
  int  down=gf2_matrix_offset_down(m);
  int right=gf2_matrix_offset_right(m);
  void *p=(void*)m->values + (row * down) + (col * right);

  gf2_u8  u8;
  gf2_u16 u16;
  gf2_u32 u32;

  if ((row < 0) || (row >= m->rows)) {
    fprintf (stderr, "Math::FastGF2::Matrix - row out of range in getval\n");
    return 0;
  }
  if ((col < 0) || (col >= m->cols)) {
    fprintf (stderr, "Math::FastGF2::Matrix - col out of range in getval\n");
    return 0;
  }

  switch (m->width) {
  case 1:
    u8=*((gf2_u8*)p);
    return u8;
  case 2:
    u16=*((gf2_u16*)p);
    return u16;
  case 4:
    u32=*((gf2_u32*)p);
    return u32;
  default:
    fprintf(stderr,"Unsupported width %d in getval\n",m->width);
    return 0;
  }
}

gf2_u32 mat_setval(SV *Self, int row, int col, gf2_u32 val) {
  gf2_matrix_t *m=(gf2_matrix_t*)SvIV(SvRV(Self));
  int  down=gf2_matrix_offset_down(m);
  int right=gf2_matrix_offset_right(m);
  void *p=(void*)m->values + (row * down) + (col * right);

  gf2_u8  u8;
  gf2_u16 u16;
  gf2_u32 u32;

  if ((row < 0) || (row >= m->rows)) {
    fprintf (stderr, "Math::FastGF2::Matrix - row out of range in setval\n");
    return;
  }

  if ((col < 0) || (col >= m->cols)) {
    fprintf (stderr, "Math::FastGF2::Matrix - col out of range in setval\n");
    return;
  }

  switch (m->width) {
  case 1:
    *((gf2_u8*)p)=(gf2_u8)val;
    break;
  case 2:
    *((gf2_u16*)p)=(gf2_u16)val;
    break;
  case 4:
    *((gf2_u32*)p)=(gf2_u32)val;
    break;
  default:
    fprintf(stderr,"Unsupported width %d in setval\n",m->width);
    break;
  }
  return val;
}

static int mat_local_byte_order (void) {
  gf2_u16 test=0x0201;
  char* first=(char*)&test;

  return (int) *first;
}

/*
  This should only be called from the Perl module code, so no checking
  on args is done. Self, Transform and Result are expected to have
  been already initialised and other values are expected to be sane.
*/
void
mat_multiply_submatrix_c (SV *Self, SV *Transform, SV *Result,
			  int self_row,  int result_row, int nrows,
			  int xform_col, int result_col, int ncols) {
  gf2_matrix_t *self   = (gf2_matrix_t*) SvIV(SvRV(Self));
  gf2_matrix_t *xform  = (gf2_matrix_t*) SvIV(SvRV(Transform));
  gf2_matrix_t *result = (gf2_matrix_t*) SvIV(SvRV(Result));
  
  /* i == input == self, t == transform, o == output == result; r <- i * t */
  /* all offsets are measured in bytes */
  int idown  = gf2_matrix_offset_down(self);
  int iright = gf2_matrix_offset_right(self);
  int tdown  = gf2_matrix_offset_down(xform); 
  int tright = gf2_matrix_offset_right(xform);
  int odown  = gf2_matrix_offset_down(result); 
  int oright = gf2_matrix_offset_right(result); 

  gf2_u8   u8,  *u8_irp,  *u8_orp,  *u8_tcp,  *u8_ocp,  *u8_vip,  *u8_vtp;
  gf2_u16 u16, *u16_irp, *u16_orp, *u16_tcp, *u16_ocp, *u16_vip, *u16_vtp;
  gf2_u32 u32, *u32_irp, *u32_orp, *u32_tcp, *u32_ocp, *u32_vip, *u32_vtp;

  int r,c,v;

  switch (self->width) {
  case 1:
    for (r=0, 
	   u8_irp=self->values   + idown * self_row, 
	   u8_orp=result->values + odown * result_row;
	 r < nrows;
	 ++r,  u8_irp += idown, u8_orp + odown) {
      for (c=0,
	     u8_tcp=xform->values  + tright * xform_col,
	     u8_ocp=result->values + oright * result_col;
	   c < ncols;
	   ++c, u8_tcp += tright, u8_ocp += oright) {
	for (v=0, 
	       u8_vip=u8_irp, u8_vtp=u8_tcp,
	       u8=gf2_mul8(*u8_vip,*u8_vtp);
	     u8_vip += iright, u8_vtp += tdown,
	       ++v < self->cols; ) {
	  u8^=gf2_mul8(*u8_vip,*u8_vtp);
	}
	*(u8_ocp + r * odown) = u8;
      }
    }
    break;

    /* 
       For 16- and 32-bit words, we have to divide offset values by
       width whenever adding them to gf2_u16 or gf2_u32 pointers since
       C increments them to point to the next word rather than the
       next byte. Other than that (and passing the correct width
       parameter to gf2_mul) there's no difference between the u8 and
       u16/u32 multiplication code
    */

  case 2:
    for (r=0, 
	   u16_irp=(gf2_u16 *) (self->values   + idown * self_row), 
	   u16_orp=(gf2_u16 *) (result->values + odown * result_row);
	 r < nrows;
	 ++r,  u16_irp +=(idown >> 1), u16_orp + (odown >> 1)) {
      for (c=0,
	     u16_tcp=(gf2_u16 *) (xform->values  + tright * xform_col),
	     u16_ocp=(gf2_u16 *) (result->values + oright * result_col);
	   c < ncols;
	   ++c, u16_tcp += (tright >> 1), u16_ocp += (oright >> 1)) {
	for (v=0, 
	       u16_vip=u16_irp, u16_vtp=u16_tcp,
	       u16=gf2_mul(16,*u16_vip,*u16_vtp);
	     u16_vip += (iright >> 1), u16_vtp += (tdown >> 1),
	       ++v < self->cols; ) {
	  u16^=gf2_mul(16,*u16_vip,*u16_vtp);
	}
	*(u16_ocp + r * (odown >> 1)) = u16;
      }
    }
    break;
    
  case 4:
    for (r=0, 
	   u32_irp=(gf2_u32 *) (self->values   + idown * self_row), 
	   u32_orp=(gf2_u32 *) (result->values + odown * result_row);
	 r < nrows;
	 ++r,  u32_irp +=(idown >> 2), u32_orp + (odown >> 2)) {
      for (c=0,
	     u32_tcp=(gf2_u32 *) (xform->values  + tright * xform_col),
	     u32_ocp=(gf2_u32 *) (result->values + oright * result_col);
	   c < ncols;
	   ++c, u32_tcp += (tright >> 2), u32_ocp += (oright >> 2)) {
	for (v=0, 
	       u32_vip=u32_irp, u32_vtp=u32_tcp,
	       u32=gf2_mul(32,*u32_vip,*u32_vtp);
	     u32_vip += (iright >> 2), u32_vtp += (tdown >> 2),
	       ++v < self->cols; ) {
	  u32^=gf2_mul(32,*u32_vip,*u32_vtp);
	}
	*(u32_ocp + r * (odown >> 2)) = u32;
      }
    }
    break;
    
  default:
    fprintf(stderr,
       "Unsupported width %d in multiply_submatrix_c\n",self->width);
  }
}


/* No error checking, so don't call directly */
int mat_values_eq_c (SV *This, SV *That) {
  gf2_matrix_t *this  = (gf2_matrix_t*) SvIV(SvRV(This));
  gf2_matrix_t *that  = (gf2_matrix_t*) SvIV(SvRV(That));

  int   thisdown, thisright;
  int   thatdown, thatright;
  int   i,j;

  char *thisp=this->values;
  char *thatp=that->values;

  if (this->organisation == that->organisation) {
    /* compare the quick/easy way */
    for (i=this->rows * this->cols * this->width;
	 i--;
	 ++thisp, ++thatp) {
      if (*thisp != *thatp) return 0;
    }
  } else {
    /* compare the slow/hard way */
    thisdown  = gf2_matrix_offset_down(this);  
    thisright = gf2_matrix_offset_right(this);
    thatdown  = gf2_matrix_offset_down(that); 
    thatright = gf2_matrix_offset_right(that);
    for (i=0; 
	 i < this-> rows;
	 ++i, 
	   thisp=this->values + i * thisdown,
	   thatp=that->values + i * thatdown) {
      for (j=0; 
	   j < this-> cols;
	   ++j, 
	     thisp+=thisright - this->width,
	     thatp+=thatright - that->width) {
	switch (this -> width) {
	case 4:
	  if (*thisp++ != *thatp++) return 0;
	  if (*thisp++ != *thatp++) return 0;
	case 2:
	  if (*thisp++ != *thatp++) return 0;
	case 1:
	  if (*thisp++ != *thatp++) return 0;
	}
      }
    }
  }
  return 1;			/* 1 == equal */
}

SV* mat_get_raw_values_c (SV *Self, int row, int col, 
			  int words, int byteorder) {
  gf2_matrix_t *self  = (gf2_matrix_t*) SvIV(SvRV(Self));
  char *from_start = self->values + 
    gf2_matrix_offset_down(self) * row +
    gf2_matrix_offset_right(self) * col;
  char *to_start;
  int len=self->width * words;
  SV *Str=newSVpv(from_start, len);
  int native_byteorder=mat_local_byte_order();
  char *from, *to;
  int i,j;
  int width=self->width;

  if ( (width > 1) && byteorder && 
       (native_byteorder != byteorder) ) {

    to_start=SvPV(Str,len) + width - 1;
    for (i=width ; i-- ; --to_start, ++from_start) {
      from=from_start; to=to_start;
      for (j=words; j--;  to += width, from += width) {
	*to=*from;
      }
;
    }
  }
  /*  sv_2mortal(Str); */ /* apparently newSVpv takes care of this */
  return Str;
}

void mat_set_raw_values_c (SV *Self, int row, int col, 
			   int words, int byteorder,
			   SV *Str) {

  gf2_matrix_t *self  = (gf2_matrix_t*) SvIV(SvRV(Self));
  int len=self->width * words;
  char *from_start;
  char *to_start= self->values + 
    gf2_matrix_offset_down(self) * row +
    gf2_matrix_offset_right(self) * col;
  int native_byteorder=mat_local_byte_order();
  char *from, *to;
  int i,j;
  int width=self->width;

  if ( (width > 1) && byteorder &&
       (native_byteorder != byteorder) ) {
    from_start=SvPV(Str,len) + width - 1;
    for (i=width ; i-- ; --from_start, ++to_start) {
      from=from_start; to=to_start;
      for (j=words; j--; to += width, from += width) {
	*to=*from;
      }
    }
  } else {
    from_start=SvPV(Str,len);
    memcpy(to_start, from_start, len);
  } 
  return;
}

/* new code to implement previous offset_to_rowcol */
