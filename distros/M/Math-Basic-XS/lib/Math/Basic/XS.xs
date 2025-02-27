#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()
#include <string.h>

double mode(double arr[], int size) {
	double max_value = 0, max_count = 0;
	int i, j;
	for (i = 0; i < size; ++i) {
		int cnt = 0;
		for (j = 0; j < size; ++j) {
			if (arr[j] == arr[i])
				++cnt;
		}
		if (cnt > max_count) {
			max_count = cnt;
			max_value = arr[i];
		}
	}
	return max_value;
}

int compare( const void* a, const void* b)
{
     double int_a = * ( (double*) a );
     double int_b = * ( (double*) b );
     
     if ( int_a == int_b ) return 0;
     else if ( int_a < int_b ) return -1;
     else return 1;
}


MODULE = Math::Basic::XS  PACKAGE = Math::Basic::XS
PROTOTYPES: ENABLE

SV *
sum(...)
	PROTOTYPE: &@
	CODE:
		SV * callback = ST(0);
		int sum = 0, i = 1;
		for (i = 1; i < items; i++) {
			dSP;
			GvSV(PL_defgv) = newSVsv(ST(i));
			PUSHMARK(SP);
			call_sv(callback, 3);
			SPAGAIN;
			SV * val = POPs;
			sum += SvNV(val);
			PUTBACK;
		}
		RETVAL = newSVnv(sum);
	OUTPUT:
		RETVAL


SV *
min(...)
	PROTOTYPE: &@
	CODE:
		SV * callback = ST(0);
		int min = 0, i = 1;
		bool set = false;
		for (i = 1; i < items; i++) {
			dSP;
			GvSV(PL_defgv) = newSVsv(ST(i));
			PUSHMARK(SP);
			call_sv(callback, G_SCALAR);
			SPAGAIN;
			SV * val = POPs;
			double ret = SvNV(val);
			if (!set || ret < min) {
				min = ret;
				set = true;
			}
			PUTBACK;
		}
		RETVAL = newSVnv(min);
	OUTPUT:
		RETVAL

SV *
max(...)
	PROTOTYPE: &@
	CODE:
		SV * callback = ST(0);
		int max = 0, i = 1;
		bool set = false;
		for (i = 1; i < items; i++) {
			dSP;
			GvSV(PL_defgv) = newSVsv(ST(i));
			PUSHMARK(SP);
			call_sv(callback, G_SCALAR);
			SPAGAIN;
			SV * val = POPs;
			int ret = SvNV(val);
			if (!set || ret > max) {
				max = ret;
				set = true;
			}
			PUTBACK;	
		}
		RETVAL = newSVnv(max);
	OUTPUT:
		RETVAL

SV *
mean(...)
	PROTOTYPE: &@
	CODE:
		SV * callback = ST(0);
		double sum = 0;
		int i = 1;
		for (i = 1; i < items; i++) {
			dSP;
			GvSV(PL_defgv) = newSVsv(ST(i));
			PUSHMARK(SP);
			call_sv(callback, 3);
			SPAGAIN;
			SV * val = POPs;
			sum += SvNV(val);
			PUTBACK;
		}
		RETVAL = newSVnv(sum / (items - 1));
	OUTPUT:
		RETVAL

SV *
median(...)
	PROTOTYPE: &@
	CODE:
		SV * callback = ST(0);
		int i;
		double median[items - 1];
		for (i = 1; i < items; i++) {
			dSP;
			GvSV(PL_defgv) = newSVsv(ST(i));
			PUSHMARK(SP);
			call_sv(callback, 3);
			SPAGAIN;
			SV * val = POPs;
			median[i - 1] = SvNV(val);
			PUTBACK;
		}
		qsort( median, items - 1, sizeof(double), compare );
		i = (items - 1) / 2;
		if (i % 2 != 0) {
			i++;
		}
		RETVAL = newSVnv(median[i]);
	OUTPUT:
		RETVAL


SV *
mode(...)
	PROTOTYPE: &@
	CODE:
		SV * callback = ST(0);
		int i;
		double arr[items - 1];
		for (i = 1; i < items; i++) {
			dSP;
			GvSV(PL_defgv) = newSVsv(ST(i));
			PUSHMARK(SP);
			call_sv(callback, 3);
			SPAGAIN;
			SV * val = POPs;
			arr[i - 1] = SvNV(val);
			PUTBACK;
		}
		RETVAL = newSVnv(mode(arr, items - 1));
	OUTPUT:
		RETVAL



