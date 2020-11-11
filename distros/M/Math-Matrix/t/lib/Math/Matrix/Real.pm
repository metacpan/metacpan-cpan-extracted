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

# We need a new() method to make sure every element is an object.

sub new {
    my $self = shift;
    my $x = $self -> SUPER::new(@_);

    my $sub = sub {
        defined(blessed($_[0])) && $_[0] -> isa('Math::Real')
          ? $_[0]
          : Math::Real -> new($_[0]);
    };

    $x -> sapply($sub);
}

1;
