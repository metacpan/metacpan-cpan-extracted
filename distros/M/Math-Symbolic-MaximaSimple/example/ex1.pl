#!/usr/bin/perl

use strict;
#undef $/;
use Math::Symbolic::MaximaSimple qw(:all);

startmaxima;
print "x+x+x+x+x**2+4\n";
print maxima_tex("x+x+x+x+x**2+4"),"\n";
print maxima_tex1("x+x+x+x+x**2+4"),"\n";
print maxima_tex2("x+x+x+x+x**2+4"),"\n";
print maxima_tex2("derivative(x+x+x+x+x**2+4,x)"),"\n";
print maxima("derivative(x+x+x+x+x**2+4,x)"),"\n";
print maxima_tex("f(x):= x*derivative(x**2,x)"),"\n";
print maxima_tex1("f(x):= x*derivative(x**2,x)"),"\n";
print maxima_tex2("f(x):= x*derivative(x**2,x)"),"\n";
print maxima("f(aa)"),"\n";
print maxima("exp(x)*sqrt(x)"),"\n";
print maxima_tex2("exp(x)*sqrt(x)"),"\n";

