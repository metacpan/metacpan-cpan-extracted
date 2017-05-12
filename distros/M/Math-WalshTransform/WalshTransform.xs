#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "math.h"
#ifdef __cplusplus
}
#endif

MODULE = Math::WalshTransform	PACKAGE = Math::WalshTransform
PROTOTYPES: ENABLE

void
xs_fht (...) 
CODE:
{
	register int i;
	double *mr;
	int j, k, l, nk, nl;

	/* perlapi SvNV for a double, SvIV for an int, SvPV for a char* etc */
	New(0, mr, items, double); /* perlapi's equivalent to malloc() */
	for (i=0; i<items; i++) mr[i] = (double) SvNV(ST(i));

	k = 1;
	l = items;
	while (1) {
		i = -1; l = l/2; j = 0;
		for (nl=1; nl<=l; nl++) {
			for (nk=1; nk<=k; nk++) {
				i++; j = i+k;
				/* fprintf (stderr, "xs_fht: nk=%d  nl=%d i=%d j=%d mr[i]=%g\n",
				 * nk, nl, i, j, mr[i]); */
				mr[i] = (mr[i] + mr[j])/2;
				mr[j] =  mr[i] - mr[j];
			}
			i = j;
		}
		k = 2*k;
		if (k >= items) { break; }
	}
	if (k == items) {
		for (i=0; i<items; i++) ST(i) = sv_2mortal(newSVnv(mr[i]));
		Safefree(mr);
		XSRETURN(items);
	} else {
		fprintf (stderr, "fht: n should be a power of 2, but was %d\n",
		 (int)items);
		XSRETURN_EMPTY;
	}
}

void
xs_fhtinv (...) 
CODE:
{
	register int i;
	double *mr;
	int j, k, l, nk, nl;

	/* perlapi SvNV for a double, SvIV for an int, SvPV for a char* etc */
	/* New() is perlapi's equivalent to malloc(). See perlclib.pod */
	New(0, mr, items, double);
	for (i=0; i<items; i++) mr[i] = (double) SvNV(ST(i));

	k = 1;
	l = items;
	while (1) {
		i = -1; l = l/2; j = 0;
		for (nl=1; nl<=l; nl++) {
			for (nk=1; nk<=k; nk++) {
				i++; j = i+k;
				/* fprintf (stderr, "xs_fht: nk=%d  nl=%d i=%d j=%d mr[i]=%g\n",
				 * nk, nl, i, j, mr[i]); */
				mr[i] = mr[i] + mr[j];
				mr[j] = mr[i] - 2.0*mr[j];
			}
			i = j;
		}
		k = 2*k;
		if (k >= items) { break; }
	}
	if (k == items) {
		for (i=0; i<items; i++) ST(i) = sv_2mortal(newSVnv(mr[i]));
		Safefree(mr);
		XSRETURN(items);
	} else {
		fprintf (stderr, "fhtinv: n should be a power of 2, but was %d\n",
		 (int)items);
		XSRETURN_EMPTY;
	}
}

void
xs_fwt (...) 
CODE:
{
	register int i;
	double *mr;
	double *nr;
	int k, l, m, nh, nk, nl, tmp, alternate, kp1, kh;

	New(0, mr, items, double); /* perlapi's malloc(). See perlclib.pod */
	for (i=0; i<items; i++) mr[i] = (double) SvNV(ST(i));
	New(0, nr, items, double);

	m = 0; tmp = 1;
	while (1) { if (tmp>=items) break; tmp<<=1; m++; }
	alternate = m & 1;

	if (alternate) {
		for (k=0; k<items; k+=2) {
			kp1 = k+1;
			mr[k]   = 0.5 * (mr[k] + mr[kp1]);
			mr[kp1] =  mr[k] - mr[kp1];
		}
	} else {
		for (k=0; k<items; k+=2) {
			kp1 = k+1;
			nr[k]   = 0.5 * (mr[k] + mr[kp1]);
			nr[kp1] =  nr[k] - mr[kp1];
		}
	}

	k = 1; nh = items/2;
	while (1) {
		kh = k; k <<= 1; kp1 = k+1; if (kp1>items) break;
		nh = nh/2; l = 0; i = 0; alternate = !alternate;
		for (nl=1; nl<=nh; nl++) {
			for (nk=1; nk<=kh; nk++) {
				if (alternate) {
					mr[l]   = 0.5 * (nr[i] + nr[i+k]);
					mr[l+1] = mr[l] - nr[i+k];
					mr[l+2] = 0.5 * (nr[i+1] - nr[i+kp1]);
					mr[l+3] = mr[l+2] + nr[i+kp1];
				} else {
					nr[l]   = 0.5 * (mr[i] + mr[i+k]);
					nr[l+1] = nr[l] - mr[i+k];
					nr[l+2] = 0.5 * (mr[i+1] - mr[i+kp1]);
					nr[l+3] = nr[l+2] + mr[i+kp1];
				}
				l = l+4; i = i+2;
			}
			i = i+k;
		}
	}
	Safefree(nr);
	for (i=0; i<items; i++) ST(i) = sv_2mortal(newSVnv(mr[i]));
	Safefree(mr);
	XSRETURN(items);
}

void
xs_fwtinv (...) 
CODE:
{
	register int i;
	double *mr;
	double *nr;
	int k, l, m, nh, nk, nl, tmp, alternate, kp1, kh;

	New(0, mr, items, double); /* perlapi's malloc(). See perlclib.pod */
	for (i=0; i<items; i++) mr[i] = (double) SvNV(ST(i));
	New(0, nr, items, double);

	m = 0; tmp = 1;
	while (1) { if (tmp>=items) break; tmp<<=1; m++; }
	alternate = m & 1;

	if (alternate) {
		for (k=0; k<items; k+=2) {
			kp1 = k+1;
			mr[k]   = mr[k] + mr[kp1];
			mr[kp1] = mr[k] - mr[kp1] - mr[kp1];
		}
	} else {
		for (k=0; k<items; k+=2) {
			kp1 = k+1;
			nr[k]   = mr[k] + mr[kp1];
			nr[kp1] = mr[k] - mr[kp1];
		}
	}

	k = 1; nh = items/2;
	while (1) {
		kh = k; k <<= 1; kp1 = k+1; if (kp1>items) break;
		nh = nh/2; l = 0; i = 0; alternate = !alternate;
		for (nl=1; nl<=nh; nl++) {
			for (nk=1; nk<=kh; nk++) {
				if (alternate) {
					mr[l]   = nr[i]   + nr[i+k];
					mr[l+1] = nr[i]   - nr[i+k];
					mr[l+2] = nr[i+1] - nr[i+kp1];
					mr[l+3] = nr[i+1] + nr[i+kp1];
				} else {
					nr[l]   = mr[i]   + mr[i+k];
					nr[l+1] = mr[i]   - mr[i+k];
					nr[l+2] = mr[i+1] - mr[i+kp1];
					nr[l+3] = mr[i+1] + mr[i+kp1];
				}
				l = l+4; i = i+2;
			}
			i = i+k;
		}
	}
	Safefree(nr);
	for (i=0; i<items; i++) ST(i) = sv_2mortal(newSVnv(mr[i]));
	Safefree(mr);
	XSRETURN(items);
}

void
product (xref, yref) 
	SV* xref
	SV* yref
CODE:
{
	register int i;
	double x, y;
	unsigned int nx, ny;
	SV** fetch;

	nx = 1+av_len((AV*)SvRV(xref));
	ny = 1+av_len((AV*)SvRV(yref));

	if (nx != ny) { fprintf (stderr,
		"product: arrays nx=%d ny=%d must be the same size \n",nx,ny);
		XSRETURN_EMPTY;
	}
	
	for (i=0; i<nx; i++) {
		fetch = av_fetch((AV*)SvRV(xref),i,0);
		if (fetch == NULL) {
			fprintf (stderr, "x[%d] was NULL\n",i); XSRETURN_EMPTY;
		}
		x = (double) SvNV(*fetch);
		fetch = av_fetch((AV*)SvRV(yref),i,0);
		if (fetch == NULL) {
			fprintf (stderr, "y[%d] was NULL\n",i); XSRETURN_EMPTY;
		}
		y = (double) SvNV(*fetch);
		ST(i) = sv_2mortal(newSVnv(x*y));
	}
	XSRETURN(nx);
}

void
size (...) 
CODE:
{
	register int i;
	double x, sumofsquares;
	sumofsquares = 0.0;
	for (i=0; i<items; i++) { x = (double) SvNV(ST(i)); sumofsquares += x*x; }
	ST(0) = sv_2mortal(newSVnv(sqrt(sumofsquares)));
	XSRETURN(1);
}

void
distance (xref, yref) 
	SV* xref
	SV* yref
CODE:
{
	register int i;
	double x, y, sumofsquares;
	unsigned int nx, ny;
	SV** fetch;
	sumofsquares = 0.0;

	nx = 1+av_len((AV*)SvRV(xref));
	ny = 1+av_len((AV*)SvRV(yref));

	if (nx != ny) { fprintf (stderr,
		"product: arrays nx=%d ny=%d must be the same size \n",nx,ny);
		XSRETURN_EMPTY;
	}
	
	for (i=0; i<nx; i++) {
		fetch = av_fetch((AV*)SvRV(xref),i,0);
		if (fetch == NULL) {
			fprintf (stderr, "x[%d] was NULL\n",i); XSRETURN_EMPTY;
		}
		x = (double) SvNV(*fetch);
		fetch = av_fetch((AV*)SvRV(yref),i,0);
		if (fetch == NULL) {
			fprintf (stderr, "y[%d] was NULL\n",i); XSRETURN_EMPTY;
		}
		y = (double) SvNV(*fetch);
		sumofsquares += (x-y)*(x-y);
	}
	ST(0) = sv_2mortal(newSVnv(sqrt(sumofsquares)));
	XSRETURN(1);
}

void
normalise (...) 
CODE:
{
	register int i;
	double x, sumofsquares, inv_size;
	sumofsquares = 0.0;

	for (i=0; i<items; i++) { x = (double) SvNV(ST(i)); sumofsquares += x*x; }
	inv_size = 1.0 / sqrt(sumofsquares);
	for (i=0; i<items; i++) {
		x = (double) SvNV(ST(i)); ST(i) = sv_2mortal(newSVnv(inv_size*x));
	}
	XSRETURN(items);
}

