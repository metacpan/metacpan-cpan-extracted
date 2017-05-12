#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "arrays.h"
#include "FFT.h"

#ifdef __cplusplus
}
#endif

MODULE = Math::FFT		PACKAGE = Math::FFT

PROTOTYPES: DISABLE

void
_cdft(n, isgn, a, ip, w)
  int n
  int isgn
  double *a
  int *ip
  double *w
  OUTPUT:
     a


void
_rdft(n, isgn, a, ip, w)
  int n
  int isgn
  double *a
  int *ip
  double *w
  OUTPUT:
     a

void
_ddct(n, isgn, a, ip, w)
  int n
  int isgn
  double *a
  int *ip
  double *w
  OUTPUT:
     a

void
_ddst(n, isgn, a, ip, w)
  int n
  int isgn
  double *a
  int *ip
  double *w
  OUTPUT:
     a

void
pdfct(nt, n, a, t, ip, w)
  int nt
  int n
  double *a
  double *t
  int *ip
  double *w
  CODE:
    coerce1D( (SV*) ST(3), nt);
    t = (double *) pack1D( (SV*) ST(3), 'd');
    _dfct(n, a, t, ip, w);
  OUTPUT:
     a

void
pdfst(nt, n, a, t, ip, w)
  int nt
  int n
  double *a
  double *t = NO_INIT
  int *ip
  double *w
  CODE:
    coerce1D( (SV*) ST(3), nt);
    t = (double *) pack1D( (SV*) ST(3), 'd');
    _dfst(n, a, t, ip, w);
  OUTPUT:
     a

void
_correl(n, corr, d1, d2, ip, w)
  int n
  double *corr = NO_INIT
  double *d1
  double *d2
  int *ip
  double *w
  PREINIT:
    int i;
  CODE:
    coerce1D( (SV*) ST(1), n);
    corr = (double *) pack1D( (SV*) ST(1), 'd');
    corr[0] = d1[0]*d2[0];
    corr[1] = d1[1]*d2[1];
    for (i=2; i<n; i+=2) {
	corr[i] = d1[i]*d2[i]+ d1[i+1]*d2[i+1];
	corr[i+1] = d1[i+1]*d2[i] - d1[i]*d2[i+1];
    }
    _rdft(n, -1, corr, ip, w);
    for (i=0; i<n; i++) corr[i] *= 2.0/n;
  OUTPUT:
     corr

void
_convlv(n, convlv, d1, d2, ip, w)
  int n
  double *convlv = NO_INIT
  double *d1
  double *d2
  int *ip
  double *w
  PREINIT:
    int i;
  CODE:
    coerce1D( (SV*) ST(1), n);
    convlv = (double *) pack1D( (SV*) ST(1), 'd');
    _rdft(n, 1, d2, ip, w);
    convlv[0] = d1[0]*d2[0];
    convlv[1] = d1[1]*d2[1];
    for (i=2; i<n; i+=2) {
	convlv[i] = d1[i]*d2[i]- d1[i+1]*d2[i+1];
	convlv[i+1] = d1[i+1]*d2[i] + d1[i]*d2[i+1];
    }
    _rdft(n, -1, convlv, ip, w);
    for (i=0; i<n; i++) convlv[i] *= 2.0/n;
  OUTPUT:
     convlv


int
_deconvlv(n, convlv, d1, d2, ip, w)
  int n
  double *convlv = NO_INIT
  double *d1
  double *d2
  int *ip
  double *w
  PREINIT:
    int i;
    double mag;
  CODE:
    coerce1D( (SV*) ST(1), n);
    convlv = (double *) pack1D( (SV*) ST(1), 'd');
    _rdft(n, 1, d2, ip, w);
    RETVAL=0;
    if (fabs((float)d2[0])<1.e-10  || fabs((float)d2[1])<1.e-10) {
       RETVAL=1;
    }
    else {
      convlv[0] = d1[0]/d2[0];
      convlv[1] = d1[1]/d2[1];
      for (i=2; i<n; i+=2) {
       	mag = d2[i]*d2[i] + d2[i+1]*d2[i+1];
	if (mag < 1.0e-10) {
           RETVAL =1;
           break;
        }
	convlv[i] = (d1[i]*d2[i]+ d1[i+1]*d2[i+1])/mag;
	convlv[i+1] = (d1[i+1]*d2[i] - d1[i]*d2[i+1])/mag;
      }
      if (RETVAL == 0) {
        _rdft(n, -1, convlv, ip, w);
        for (i=0; i<n; i++) convlv[i] *= 2.0/n;
      }
    }
  OUTPUT:
   convlv
   RETVAL

void
_spctrm(n, spctrm, data, ip, w, n2, flag)
   int n
   double *spctrm = NO_INIT
   double *data
   int *ip
   double *w
   double n2
   int flag
  PREINIT:
    int i;
  CODE:
    coerce1D( (SV*) ST(1), n/2+1);
    spctrm = (double *) pack1D( (SV*) ST(1), 'd');
    if (flag == 1) _rdft(n, 1, data, ip, w);
    spctrm[0] = data[0]*data[0] / n2;
    spctrm[n/2] = data[1]*data[1] / n2;
    for (i=1; i<n/2; i++) {
      spctrm[i] = 2*(data[2*i]*data[2*i]+ data[2*i+1]*data[2*i+1])/n2;
    }
  OUTPUT:
     spctrm

void
_spctrm_bin(k, m, spctrm, data, ip, w, n2, tmp)
   int k
   int m
   double *spctrm = NO_INIT
   double2D *data
   int *ip
   double *w
   double n2
   double *tmp = NO_INIT
  PREINIT:
     int i, j, n;
     double den = 0.0;
  CODE:
    coerce1D( (SV*) ST(2), m/2+1);
    spctrm = (double *) pack1D( (SV*) ST(2), 'd');
    coerce1D( (SV*) ST(7), m);
    tmp = (double *) pack1D( (SV*) ST(7), 'd');
    for(i=0; i<k*m; i+=m) {
      for (j=0; j<m; j++) tmp[j] = data[i+j];
      _rdft(m, 1, tmp, ip, w);
      spctrm[0] += tmp[0]*tmp[0];
      spctrm[m/2] += tmp[1]*tmp[1];
      den += n2;
      for (n=1; n<m/2; n++)
        spctrm[n] += 2*(tmp[2*n]*tmp[2*n]+ tmp[2*n+1]*tmp[2*n+1]);
    }
    den *= m;
    for (j=0; j<=m/2; j++) spctrm[j] /= den;
  OUTPUT:
     spctrm

