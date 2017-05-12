#ifndef _INC_FFT
#define _INC_FFT

void _cdft(int, int, double *, int *, double *);
void _rdft(int, int, double *, int *, double *);
void _ddct(int, int, double *, int *, double *);
void _ddst(int, int, double *, int *, double *);
void _dfct(int, double *, double *, int *, double *);
void _dfst(int, double *, double *, int *, double *);
typedef double double2D;

#endif
