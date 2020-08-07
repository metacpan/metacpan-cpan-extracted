#!perl

# Math::Matrix::Complex is a subclass of Math::Matrix where each element is a
# Math::Complex object. The main purpose of this class is to test subclassing
# of Math::Matrix. See also Math::Matrix::Real.

use strict;
use warnings;

package Math::Matrix::Complex;

use Math::Matrix;
use Scalar::Util 'blessed';

use Math::Complex;

our @ISA = ('Math::Matrix');

sub new {
    my $self = shift;
    my $x = $self -> SUPER::new(@_);

    # Loop over all elements and make each one a Math::Complex object.

    my $imax = $#$x;
    my $jmax = $#{$x -> [0]};
    for (my $i = 0 ; $i <= $imax ; ++$i) {
        for (my $j = 0 ; $j <= $jmax ; ++$j) {
            $x -> [$i][$j] = Math::Complex -> new($x -> [$i][$j])
              unless blessed($x -> [$i][$j])
                       && $x -> [$i][$j] -> isa('Math::Complex');
        }
    }

    return $x;
}

sub as_string {
    my $self = shift;
    my $out = "";
    for my $row (@{$self}) {
        for my $col (@{$row}) {
            $out = $out . sprintf "%10s ", $col;
        }
        $out = $out . sprintf "\n";
    }
    $out;
}

sub transpose {
    my $x = shift;
    my $y = $x -> SUPER::transpose(@_);

    # Loop over all elements and take the complex conjugate of each one.

    my $imax = $#$y;
    my $jmax = $#{$y -> [0]};
    for (my $i = 0 ; $i <= $imax ; ++$i) {
        for (my $j = 0 ; $j <= $jmax ; ++$j) {
            $y -> [$i][$j] = ~$y -> [$i][$j];
        }
    }

    return $y;
}

1;
