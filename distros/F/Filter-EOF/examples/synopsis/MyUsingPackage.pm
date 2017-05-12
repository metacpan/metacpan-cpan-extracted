package MyUsingPackage;
use warnings;
use strict;

our $COMPILE_TIME;
use MyPackage;

# prints 'yes'
BEGIN { print +( $COMPILE_TIME ? 'yes' : 'no' ), "\n" }

# prints 'no'
print +( $COMPILE_TIME ? 'yes' : 'no' ), "\n";

1;
