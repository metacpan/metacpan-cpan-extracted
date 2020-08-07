#!perl

# Math::Matrix::Real is a subclass of Math::Matrix where each element is a
# Math::Real object. The main purpose of this class is to test subclassing of
# Math::Matrix. See also Math::Matrix::Complex.

use strict;
use warnings;

package Math::Matrix::Real;

use Math::Matrix;
use Scalar::Util 'blessed';

use Math::Real;

our @ISA = ('Math::Matrix');

sub new {
    my $self = shift;
    my $x = $self -> SUPER::new(@_);

    # Loop over all elements and make each one a Math::Real object.

    my $imax = $#$x;
    my $jmax = $#{$x -> [0]};
    for (my $i = 0 ; $i <= $imax ; ++$i) {
        for (my $j = 0 ; $j <= $jmax ; ++$j) {
            $x -> [$i][$j] = Math::Real -> new($x -> [$i][$j])
              unless blessed($x -> [$i][$j])
                       && $x -> [$i][$j] -> isa('Math::Real');
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

sub clone {
    my $x = shift;
    my $y = $x -> SUPER::clone(@_);

    my $imax = $#$x;
    my $jmax = $#{$x -> [0]};
    for (my $i = 0 ; $i <= $imax ; ++$i) {
        for (my $j = 0 ; $j <= $jmax ; ++$j) {
            $y -> [$i][$j] = $y -> [$i][$j] -> clone();
        }
    }

    return $y;
}

1;
