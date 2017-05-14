#ifndef BASE_H
#define BASE_H

#include "macopt.h"
#include "callperl.h"

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

class Base : public Macopt
{
public:
	Base(
		int		 _n, 
		int		_verbose=0, 
		double 	_tolerance=0.001, 
		int 	_itmax=100, 
		int 	_rich = 1
	);
	double func(double* _p);
	void dfunc(double* _p, double* _g);
	int size();

	void setFunc(SV* callback);
	void setDfunc(SV* callback);
private:
	SV* cbFunc;
	SV* cbDfunc;
};

#endif

