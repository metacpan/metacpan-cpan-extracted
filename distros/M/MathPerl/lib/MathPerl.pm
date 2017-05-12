# [[[ HEADER ]]]
package MathPerl;
use strict;
use warnings;
use RPerl::AfterSubclass;
our $VERSION = 0.100_000;

# [[[ OO INHERITANCE ]]]
use parent qw(RPerl::CompileUnit::Module::Class);  # no non-system inheritance, only inherit from base class
use RPerl::CompileUnit::Module::Class;

# [[[ INCLUDES ]]]
use MathPerl::Config;
#use MathPerl::GeometricAlgebra;  # ERROR ECOCODE01: circular dependency
#use MathPerl::Geometry;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

1;    # end of class
