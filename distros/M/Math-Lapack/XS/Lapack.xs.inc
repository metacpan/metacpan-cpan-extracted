#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "C/matrix.h"

MODULE = Math::Lapack    PACKAGE = Math::Lapack::Matrix

SV *
_zeros (rows, cols)
    int rows;
    int cols;

    PREINIT:
        Matrix* m;

    CODE:
        m = zeros(rows, cols);
        RETVAL = newSVuv((unsigned long)m);

    OUTPUT:
        RETVAL


SV *
_ones (rows, cols)
    int rows;
    int cols;

    PREINIT:
        Matrix* m;

    CODE:
        m = ones(rows, cols);
        RETVAL = newSVuv((unsigned long)m);

    OUTPUT:
        RETVAL

SV *
_random(rows, cols)
	int rows;
	int cols;
	
	PREINIT:
		Matrix* m;

	CODE:
		m = matrix_random(rows, cols);
		RETVAL = newSVuv((unsigned long)m);

	OUTPUT:
		RETVAL

SV *
_identity(rows)
	int rows;

	PREINIT:
		Matrix *m;

	CODE:
		m = identity(rows);
		RETVAL = newSVuv((unsigned long)m);
	OUTPUT:
		RETVAL
	 
SV *
_get_element (m, r, c)
    unsigned long m;
    int r;
    int c;

    CODE:
        RETVAL = newSVnv(get_element((Matrix*)m, r, c));

    OUTPUT:
        RETVAL

SV *
_get_max (m)
    unsigned long m;

    CODE:
        RETVAL = newSVnv(get_max((Matrix*)m));
    OUTPUT:
        RETVAL


SV *
_get_min (m)
	unsigned long m;

	CODE:
		RETVAL = newSVnv(get_min((Matrix*)m));
	OUTPUT:
		RETVAL


SV *
_mean (m)
	unsigned long m;

	CODE:
		RETVAL = newSVnv(mean((Matrix*)m));
	OUTPUT:
		RETVAL


SV *
_standard_deviation(m)
	unsigned long m;

	CODE:
		RETVAL = newSVnv(standard_deviation((Matrix*)m));
	OUTPUT:
		RETVAL


void
_set_element (m, r, c, v)
    unsigned long m;
    int r;
    int c;
    REAL v;

    CODE:
        set_element((Matrix*)m, r, c, v);

SV *
_dot(a, b, tA, tB)
        unsigned long a;
        unsigned long b;
        int tA;
        int tB;

        PREINIT:
                Matrix *m;

        CODE:
                m = dot((Matrix *)a,(Matrix*)b, tA, tB);
                RETVAL = newSVuv((unsigned long)m);

        OUTPUT:
                RETVAL

SV *
_rows(a)
    unsigned long a;

    CODE:
       RETVAL = newSVuv(((Matrix*)a)->rows);
    OUTPUT:
       RETVAL

SV *
_cols(a)
    unsigned long a;

    CODE:
       RETVAL = newSVuv(((Matrix*)a)->columns);
    OUTPUT:
       RETVAL

SV *
__add_matrices(a, b)
	unsigned long a;
	unsigned long b;

	PREINIT:
		Matrix *m;

	CODE:
		m = sum_matrices((Matrix*)a, (Matrix*)b);
    	RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
__sub_matrices(a, b)
	unsigned long a;
	unsigned long b;

	PREINIT:
		Matrix *m;

	CODE:
		m = sub_matrices((Matrix*)a, (Matrix*)b);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
__mul_matrices(a, b)
	unsigned long a;
	unsigned long b;

	PREINIT:
		Matrix *m;

	CODE:
		m = mul_matrices((Matrix*)a, (Matrix*)b);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

    
SV *
__div_matrices(a, b)
	unsigned long a;
	unsigned long b;

	PREINIT:
		Matrix *m;

	CODE:
		m = div_matrices((Matrix*)a, (Matrix*)b);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
_concatenate(a, b, index)
	unsigned long a;
	unsigned long b;
	int index;

	PREINIT:
		Matrix *m;

	CODE:
		m = concatenate((Matrix*)a, (Matrix*)b, index);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL
		
SV *
_destroy(m)
	unsigned long m;

	CODE:
		destroy((Matrix*)m);

SV *
_matrix_mul(a, v)
    	unsigned long a;
    	REAL v;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_mul((Matrix*)a, v);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL
	
SV *
_matrix_div(a, v, swap)
    	unsigned long a;
    	REAL v;
        int swap;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_div((Matrix*)a, v, swap);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL
	
SV *
_matrix_sum(a, v)
    	unsigned long a;
    	REAL v;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_sum((Matrix*)a, v);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
_matrix_sub(a, v, swap)
    	unsigned long a;
    	REAL v;
        int swap;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_sub((Matrix*)a, v, swap);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

void
_matrix_save(m, p)
	unsigned long m;
	char *p;

	CODE:
		save((Matrix*)m, p);

SV *
_matrix_read(p)
	char *p;

	PREINIT:
		Matrix *m;

	CODE:
		m = read_matrix(p);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL

SV *
_transpose(m)
	unsigned long m;

	PREINIT:
		Matrix *t;

	CODE:
		t = transpose((Matrix*)m);
		RETVAL = newSVuv((unsigned long)t);

	OUTPUT:
		RETVAL

SV *
_inverse(m)
	unsigned long m;

	PREINIT:
		Matrix *i;

	CODE:
		i = inverse((Matrix*)m);
		RETVAL = newSVuv((unsigned long)i);

	OUTPUT:
		RETVAL

SV *
_normalize_std_deviation(a)
	unsigned long a;

	PREINIT:
		Matrix *m;

	CODE:
		m = normalize_std_deviation((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);

	OUTPUT:
		RETVAL


SV *
_normalize_mean(a)
	unsigned long a;

	PREINIT:
		Matrix *m;

	CODE:
		m = normalize_mean((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);

	OUTPUT:
		RETVAL
		
void
_norm_mean_data(a,b)
	unsigned long a;
	unsigned long b;

	CODE:
		normalize_mean_data((Matrix*)a, (Matrix*)b);

void
_norm_std_deviation_data(a,b)
	unsigned long a;
	unsigned long b;

	CODE:
		normalize_std_deviation_data((Matrix*)a, (Matrix*)b);

SV *
_pow(a, v)
    	unsigned long a;
    	REAL v;

	PREINIT:	
		Matrix* m;

	CODE:
		m = matrix_pow((Matrix*)a, v);
		RETVAL = newSVuv((unsigned long)m);
	
	OUTPUT:
		RETVAL


SV *
_log(a)
	unsigned long a;

	PREINIT:
		Matrix *m;

	CODE:
		m = matrix_log((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);

	OUTPUT:
		RETVAL

SV *
_slice(s, x0, x1, y0, y1)
	unsigned long s;
	int x0;
	int x1;
	int y0;
	int y1;

	PREINIT:
		Matrix* m;

	CODE:
		m = slice((Matrix*)s, x0, x1, y0, y1);
		RETVAL = newSVuv((unsigned long)m);
    
    OUTPUT:
        RETVAL

SV *
_exp(a)
	unsigned long a;

	PREINIT:
		Matrix *m;

	CODE:
		m = matrix_exp((Matrix*)a);
		RETVAL = newSVuv((unsigned long)m);

	OUTPUT:
		RETVAL


SV *
_sum(a, v)
	unsigned long a;
	int v;

	PREINIT:
		Matrix* m;

	CODE:
		m = sum((Matrix*)a, v);
		RETVAL = newSVuv((unsigned long)m);

	OUTPUT:
		RETVAL

MODULE = Math::Lapack    PACKAGE = Math::Lapack
    
void
_srand(v)
    unsigned long v;

    CODE:
        srand(v);
    
