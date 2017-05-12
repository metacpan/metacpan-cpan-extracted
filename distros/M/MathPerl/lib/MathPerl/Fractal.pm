# [[[ HEADER ]]]
use RPerl;
package MathPerl::Fractal;
use strict;
use warnings;
our $VERSION = 0.000_001;

# [[[ OO INHERITANCE ]]]
use parent qw(MathPerl);
use MathPerl;

# [[[ INCLUDES ]]]
#use MathPerl::Fractal::Mandelbrot;  # ERROR ECOCODE01: circular dependency
#use MathPerl::Fractal::Julia;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

1;    # end of class
