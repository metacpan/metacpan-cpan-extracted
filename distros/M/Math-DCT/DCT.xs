#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef M_PI
    #define M_PI 3.14159265358979323846
#endif

void transform_recursive(double input[], double temp[], int size, double coef[]);

void dct_1d(
    char *inbuf,
    int   size)
{
    double *input  = (double *) inbuf;
    double  temp[size];
    double  factor = M_PI/size;

    int i,j;
    for(i = 0; i < size; ++i) {
        double sum = 0;
        for(j = 0; j < size; ++j) {
            sum += input[j] * cos((j+0.5)*i*factor);
        }
        temp[i]=sum;
    }

    for(i = 0; i < size; ++i) {
        input[i]=temp[i];
    }
}

void dct_coef(int size, double coef[size][size]) {
    double factor = M_PI/size;

    int i, j;
    for (i = 0; i < size; i++) {
        for (j = 0; j < size; j++) {
            coef[j][i] = cos((j+0.5)*i*factor);
        }
    }
}

void dct_2d(
    char *inbuf,
    int   size)
{
    double *input = (double *) inbuf;
    double  coef[size][size];
    double  temp[size*size];
    int x, y, i, j;

    dct_coef(size, coef);

    for (x = 0; x < size; x++) {
        for (i = 0; i < size; i++) {
            double sum = 0;
            for (j = 0; j < size; j++) {
                sum += input[x*size+j] * coef[j][i];
            }
            temp[x*size+i] = sum;
        }
    }

    for (y = 0; y < size; y++) {
        for (i = 0; i < size; i++) {
            double sum = 0;
            for (j = 0; j < size; j++) {
                sum += temp[j*size+y] * coef[j][i];
            }
            input[i*size+y] = sum;
        }
    }
}

void fast_dct_1d_precalc(
    char *inbuf,
    int   size,
    double coef[])
{
    double *input = (double *) inbuf;
    double  temp[size];

    transform_recursive(input, temp, size, coef);
}

void fast_dct_coef(int size, double coef[size]) {

    int i, j;
    for (i = 1; i <= size/2; i*=2) {
        double factor = M_PI/(i*2);
        for (j = 0; j < i; j++) {
            coef[i+j] = cos((j+0.5)*factor)*2;
        }
    }
}

void fast_dct_1d(
    char *inbuf,
    int   size)
{
    double  coef[size];

    fast_dct_coef(size, coef);

    fast_dct_1d_precalc(inbuf, size, coef);
}

void fast_dct_2d(
    char *inbuf,
    int   size)
{
    double *input = (double *) inbuf;
    double  coef[size];
    double  temp[size*size];
    int x,y;

    fast_dct_coef(size, coef);

    for (x = 0; x < size*size; x+=size) {
        fast_dct_1d_precalc((char *)&input[x], size, coef);
    }

    for (x = 0; x < size; x++) {
        for (y = 0; y < size; y++) {
            temp[y*size+x]=input[x*size+y];
        }
    }

    for (y = 0; y < size*size; y+=size) {
        fast_dct_1d_precalc((char *)&temp[y], size, coef);
    }

    for (x = 0; x < size; x++) {
        for (y = 0; y < size; y++) {
            input[y*size+x]=temp[x*size+y];
        }
    }
}

void transform_recursive(double input[], double temp[], int size, double coef[]) {
    if (size == 1)
        return;

    int i;
    int half = size / 2;

    for (i = 0; i < half; i++) {
        double x = input[i];
        double y = input[size-1-i];
        temp[i]  = x+y;
        temp[i+half] = (x-y)/coef[half+i];
    }

    transform_recursive(temp, input, half, coef);
    transform_recursive(&temp[half], input, half, coef);

    for (i = 0; i < half-1; i++) {
        input[i*2+0] = temp[i];
        input[i*2+1] = temp[i+half] + temp[i+half+1];
    }
    input[size-2] = temp[half-1];
    input[size-1] = temp[size-1];
}


MODULE = Math::DCT  PACKAGE = Math::DCT  

PROTOTYPES: DISABLE


void
dct_1d (inbuf, size)
    char *  inbuf
    int size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        dct_1d(inbuf, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
dct_2d (inbuf, size)
    char *  inbuf
    int size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        dct_2d(inbuf, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fast_dct_1d (inbuf, size)
    char *  inbuf
    int size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fast_dct_1d(inbuf, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fast_dct_2d (inbuf, size)
    char *  inbuf
    int size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fast_dct_2d(inbuf, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

