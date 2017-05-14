#include <stdio.h> 
#include "base.h"

// 1) Call superclass contructor
// 2) Initialize the callbacks as "undef" (PERL)
// Base::Base(int _n) : Macopt(_n) {
Base::Base(int _n, int _verbose, double _tolerance, int _itmax, int _rich) :
Macopt(_n, _verbose, _tolerance, _itmax, _rich)   
{
	cbFunc = NULL;
	cbDfunc = NULL;
}

// Update the reference of func()
void Base::setFunc(SV* callback)
{
	if (cbFunc != NULL) {
		SvREFCNT_dec(cbFunc);
	}
	cbFunc = callback;
	SvREFCNT_inc(callback);
}

// Update the reference of dfunc()
void Base::setDfunc(SV* callback)
{
	if (cbDfunc != NULL) {
		SvREFCNT_dec(cbDfunc);
	}
	cbDfunc = callback;
	SvREFCNT_inc(callback);
}

// Change C variable in PERL 
// Call the func() in PERL
// Convert back the return to C
double Base::func(double *x)
{
	if (cbFunc == NULL) {
		printf("func() not yet defined.\n");
		exit(0);
	}
	
	double value = 0;

	// Push value into the PERL array
	AV* vector = newAV();
	av_clear(vector);
	for (int i=1; i<=a_n; i++) {
		av_push(vector, newSVnv(x[i]));
	}
	
	// Create the AV list to store the genes
	AV* args = newAV();
	av_clear(args);
	av_push(args, newRV((SV*) vector));

	// Interact with the perl callback
	AV* returns = interactPerl(cbFunc, args);

	// Get the return value 
	value = SvNV(av_fetch(returns, 0, 0)[0]);

	// Clean up the temp AV
	av_undef(args);
	av_undef(vector);
	av_undef(returns);
	
	return value; 
}
	
// Change C variable in PERL 
// Call the func() in PERL
// Convert back the return PERL array into to C pass-by-pointer
void Base::dfunc(double *x, double *g)
{
	if (cbDfunc == NULL) {
		printf("dfunc() not yet defined.\n");
		exit(0);
	}
	
	// Push value into the PERL array
	AV* vector = newAV();
	av_clear(vector);
	for (int i=1; i<=a_n; i++) {
		av_push(vector, newSVnv(x[i]));
	}
	
	// Create the AV list to store the genes
	AV* args = newAV();
	av_clear(args);
	av_push(args, newRV((SV*) vector));

	// Interact with the perl callback
	AV* returns = interactPerl(cbDfunc, args);
	AV* gradient = (AV*) SvRV( av_fetch(returns, 0, 0)[0] );
	
	// Get the return value
	for (int i=1; i<=a_n; i++) {
		g[i] = SvNV(av_fetch(gradient, 0, 0)[i-1]);
	}

	// Clean up the temp AV
	av_undef(args);
	av_undef(vector);
}

int Base::size()
{
	return a_n;
}
