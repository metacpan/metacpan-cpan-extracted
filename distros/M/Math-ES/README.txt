---------------------------------------------------------------------------
Math::ES 
Version 0.08
---------------------------------------------------------------------------
Prerequisites: Math::Random
---------------------------------------------------------------------------

General Info:
-------------
This package provides an object orientated Evolution
Strategy (ES) for function minimization. It supports multiple
populations, elitism, migration, isolation, two selection schemes and
self-adapting step widths.

See POD documentation within the module for more information.
There are also some LaTeX parts in the POD, so if you are interested
in all details use pod2latex: 
  pod2latex -full -modify ES.pm; latex ES.tex; xdvi ES.dvi

For an (working) example please see the test routines in test.pl.


Installation:
-------------
Use the well-known mantra

 > perl Makefile.PL
 > make
 > make test
 > make install

(If one of the tests fail, rerun the test suite; because random numbers are
involved, the optimization may not converge within in specified cycle number.)



Fuerth, 09-Jun-2003

Anselm H. C. Horn

