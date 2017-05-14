use strict;
use warnings;

## Generate 100 numbers from 0 to 100 and print them to STDOUT.

use Math::Random::GaussianRange;

my $rh = {
    min   => 0,    
    max   => 100,
    n     => 100, 
    round => 0, 
};

my $ra = generate_normal_range( $rh );

print join "\n", @$ra;

print "\n";