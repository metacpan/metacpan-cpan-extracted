%include typemaps.i

%{
typedef struct {
    double n;
    double d;
} fract;

typedef struct {
    double r;
    double i;
} cmplx;

typedef double * arr1d;
typedef int * arr1i;
%}


%typemap(in) arr1d {
  $1 = (double *) pack1D($input,'d');
}

%typemap(in) arr1i {
  $1 = (int *) pack1D($input,'i');
}

%typemap(argout) arr1d {
  unpack1D((SV*)$input, (void *)$1, 'd', 0);
}

%typemap(argout) arr1i {
  unpack1D((SV*)$input, (void *)$1, 'i', 0);
}

typedef struct {
	double r;
	double i;
        %extend {
	  cmplx(double r=0, double i=0) {
   	    cmplx *c;
  	    c = (cmplx *) malloc(sizeof(cmplx));
    	    c->r = r;
    	    c->i = i;
    	    return c;
	  }
	  ~cmplx() {
	    free(self);
	  }
	}
} cmplx;

typedef struct {
	double n;
	double d;
        %extend {
	  fract(double n=0, double d=1) {
   	    fract *f;
  	    f = (fract *) malloc(sizeof(fract));
    	    f->n = n;
    	    f->d = d;
    	    return f;
	  }
	  ~fract() {
	    free(self);
	  }
	}
} fract;


extern double MACHEP;
extern double MAXLOG;
extern double MINLOG;
extern double MAXNUM;
extern double PI;
extern double PIO2;
extern double PIO4;
extern double SQRT2;
extern double SQRTH;
extern double LOG2E;
extern double SQ2OPI;
extern double LOGE2;
extern double LOGSQ2;
extern double THPIO4;
extern double TWOOPI;

extern double md_acosh ( double x );
extern int airy ( double x, double *OUTPUT, double *OUTPUT, double *OUTPUT, double *OUTPUT );
extern double md_asin ( double x );
extern double md_acos ( double x );
extern double md_asinh ( double x );
extern double md_atan ( double x );
extern double md_atan2 ( double y, double x );
extern double md_atanh ( double x );
extern double bdtrc ( int k, int n, double p );
extern double bdtr ( int k, int n, double p );
extern double bdtri ( int k, int n, double y );
extern double beta ( double a, double b );
extern double lbeta ( double a, double b );
extern double btdtr ( double a, double b, double x );
extern double md_cbrt ( double x );
extern double chbevl ( double x, void *P, int n );
extern double chdtrc ( double df, double x );
extern double chdtr ( double df, double x );
extern double chdtri ( double df, double y );
extern void md_clog ( cmplx *z, cmplx *w );
extern void md_cexp ( cmplx *z, cmplx *w );
extern void md_csin ( cmplx *z, cmplx *w );
extern void md_ccos ( cmplx *z, cmplx *w );
extern void md_ctan ( cmplx *z, cmplx *w );
extern void ccot ( cmplx *z, cmplx *w );
extern void md_casin ( cmplx *z, cmplx *w );
extern void md_cacos ( cmplx *z, cmplx *w );
extern void md_catan ( cmplx *z, cmplx *w );
extern void md_csinh ( cmplx *z, cmplx *w );
extern void md_casinh ( cmplx *z, cmplx *w );
extern void md_ccosh ( cmplx *z, cmplx *w );
extern void md_cacosh ( cmplx *z, cmplx *w );
extern void md_ctanh ( cmplx *z, cmplx *w );
extern void md_catanh ( cmplx *z, cmplx *w );
extern void md_cpow ( cmplx *a, cmplx *z, cmplx *w );
extern void radd ( fract *a, fract *b, fract *c );
extern void rsub ( fract *a, fract *b, fract *c );
extern void rmul ( fract *a, fract *b, fract *c );
extern void rdiv ( fract *a, fract *b, fract *c );
extern double euclid ( double *INOUT, double *INOUT);
extern void cadd ( cmplx *a, cmplx *b, cmplx *c );
extern void csub ( cmplx *a, cmplx *b, cmplx *c );
extern void cmul ( cmplx *a, cmplx *b, cmplx *c );
extern void cdiv ( cmplx *a, cmplx *b, cmplx *c );
extern void cmov ( void *a, void *b );
extern void cneg ( cmplx *a );
extern double md_cabs ( cmplx *z );
extern void md_csqrt ( cmplx *z, cmplx *w );
extern double md_hypot ( double x, double y );
extern double md_cosh ( double x );
extern double dawsn ( double xx );
extern double ellie ( double phi, double m );
extern double ellik ( double phi, double m );
extern double ellpe ( double x );
extern int ellpj ( double u, double m, double *OUTPUT, double *OUTPUT, double *OUTPUT, double *OUTPUT );
extern double ellpk ( double x );
extern double md_exp ( double x );
extern double md_exp10 ( double x );
/* extern double exp1m ( double x ); */
extern double md_exp2 ( double x );
extern double md_expn ( int n, double x );
extern double ei ( double x );
extern double md_fabs ( double x );
extern double fac ( int i );
extern double fdtrc ( int ia, int ib, double x );
extern double fdtr ( int ia, int ib, double x );
extern double fdtri ( int ia, int ib, double y );
extern double md_ceil ( double x );
extern double md_floor ( double x );
extern double md_frexp ( double x, int *OUTPUT);
/* extern double md_frexp ( double x, int *pw2 ); */
extern double md_ldexp ( double x, int pw2 );
/* extern int signbit ( double x ); */
/* extern int isnan ( double x ); */
/* extern int isfinite ( double x ); */
extern int fresnl ( double xxa, double *OUTPUT, double *OUTPUT);
extern double md_gamma ( double x );
extern double lgam ( double x );
extern double gdtr ( double a, double b, double x );
extern double gdtrc ( double a, double b, double x );
extern double hyp2f1 ( double a, double b, double c, double x );
extern double hyperg ( double a, double b, double x );
extern double hyp2f0 ( double a, double b, double x, int type, double *OUTPUT );
extern double i0 ( double x );
extern double i0e ( double x );
extern double i1 ( double x );
extern double i1e ( double x );
extern double igamc ( double a, double x );
extern double igam ( double a, double x );
extern double igami ( double a, double md_y0 );
extern double incbet ( double aa, double bb, double xx );
extern double incbi ( double aa, double bb, double yy0 );
extern double iv ( double v, double x );
extern double md_j0 ( double x );
extern double md_y0 ( double x );
extern double md_j1 ( double x );
extern double md_y1 ( double x );
extern double md_jn ( int n, double x );
extern double jv ( double n, double x );
extern double k0 ( double x );
extern double k0e ( double x );
extern double k1 ( double x );
extern double k1e ( double x );
extern double kn ( int nn, double x );
extern double md_log ( double x );
extern double md_log10 ( double x );
extern double md_log2 ( double x );
extern long lrand ( void );
extern long lsqrt ( long x );
extern int mtherr ( char *name, int code );
extern double polevl ( double x, void *P, int N );
extern double p1evl ( double x, void *P, int N );
extern double nbdtrc ( int k, int n, double p );
extern double nbdtr ( int k, int n, double p );
extern double nbdtri ( int k, int n, double p );
extern double ndtr ( double a );
extern double md_erfc ( double a );
extern double md_erf ( double x );
extern double ndtri ( double md_y0 );
extern double pdtrc ( int k, double m );
extern double pdtr ( int k, double m );
extern double pdtri ( int k, double y );
extern double md_pow ( double x, double y );
extern double md_powi ( double x, int nn );
extern double psi ( double x );
extern double rgamma ( double x );
extern double md_round ( double x );
extern int shichi ( double x, double *OUTPUT, double *OUTPUT );
extern int sici ( double x, double *OUTPUT, double *OUTPUT );
extern double md_sin ( double x );
extern double md_cos ( double x );
extern double radian ( double d, double m, double s );
/*
extern int sincos ( double x, double *OUTPUT, double *OUTPUT, int flg );
*/
extern double md_sindg ( double x );
extern double cosdg ( double x );
extern double md_sinh ( double x );
extern double spence ( double x );
extern double sqrt ( double x );
extern double stdtr ( int k, double t );
extern double stdtri ( int k, double p );
extern double onef2 ( double a, double b, double c, double x, double *OUTPUT );
extern double threef0 ( double a, double b, double c, double x, double *OUTPUT );
extern double struve ( double v, double x );
extern double md_tan ( double x );
extern double cot ( double x );
extern double tandg ( double x );
extern double cotdg ( double x );
extern double md_tanh ( double x );
extern double md_log1p ( double x );
extern double expm1 ( double x );
extern double cosm1 ( double x );
extern double md_yn ( int n, double x );
extern double yv ( double n, double x );
extern double zeta ( double x, double q );
extern double zetac ( double x );
extern int drand ( double *OUTPUT );
extern double plancki(double w, double T);

extern void polini( int maxdeg );
extern void polmul ( arr1d A, int na, arr1d B, int nb, arr1d C );
extern int poldiv ( arr1d A, int na, arr1d B, int nb, arr1d C);
extern void poladd ( arr1d A, int na, arr1d B, int nb, arr1d C );
extern void polsub ( arr1d A, int na, arr1d B, int nb, arr1d C );
extern void polsbt ( arr1d A, int na, arr1d B, int nb, arr1d C );
extern double poleva (arr1d A, int na, double x);
extern void polatn(arr1d A, arr1d B, arr1d C, int n);
extern void polsqt(arr1d A, arr1d B, int n);
extern void polsin(arr1d A, arr1d B, int n);
extern void polcos(arr1d A, arr1d B, int n);
extern int polrt_wrap(arr1d xcof, arr1d cof, int m, arr1d r, arr1d i);
extern int cpmul_wrap(arr1d ar, arr1d ai, int da, arr1d br, arr1d bi, int db, arr1d cr, arr1d ci, int *INOUT);

extern void fpolini( int maxdeg );
extern void fpolmul_wrap ( arr1d A, arr1d Ad, int na, arr1d Bn, arr1d Bd, int nb, arr1d Cn, arr1d Cd, int nc );
extern int fpoldiv_wrap ( arr1d A, arr1d Ad, int na, arr1d Bn, arr1d Bd, int nb, arr1d Cn, arr1d Cd, int nc);
extern void fpoladd_wrap ( arr1d A, arr1d Ad, int na, arr1d Bn, arr1d Bd, int nb, arr1d Cn, arr1d Cd, int nc );
extern void fpolsub_wrap ( arr1d A, arr1d Ad, int na, arr1d Bn, arr1d Bd, int nb, arr1d Cn, arr1d Cd, int nc );
extern void fpolsbt_wrap ( arr1d A, arr1d Ad, int na, arr1d Bn, arr1d Bd, int nb, arr1d Cn, arr1d Cd, int nc );
extern void fpoleva_wrap( arr1d An, arr1d Ad, int na, fract *x, fract *s);

extern void bernum_wrap(arr1d num, arr1d den);
extern double simpsn_wrap(arr1d f, int n, double h);
extern int minv(arr1d A, arr1d X, int n, arr1d B, arr1i IPS);
extern void mtransp(int n, arr1d A, arr1d X);
extern void eigens(arr1d A, arr1d EV, arr1d E, int n);
extern int simq(arr1d A, arr1d B, arr1d X, int n, int flag, arr1i IPS);
extern double polylog(int n, double x);
extern double arcdot(arr1d p, arr1d q);
extern double expx2(double x, int sign);
