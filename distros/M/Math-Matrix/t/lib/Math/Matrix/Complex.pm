#!perl

# Math::Matrix::Complex is a subclass of Math::Matrix where each element is a
# Math::Complex object. The main purpose of this class is to test subclassing of
# Math::Matrix. See also Math::Matrix::Real.

use strict;
use warnings;

package Math::Matrix::Complex;

use Math::Matrix;
use Scalar::Util 'blessed';
use Math::Complex;

our @ISA = ('Math::Matrix');

# We need a new() method to make sure every element is an object.

sub new {
    my $self = shift;
    my $x = $self -> SUPER::new(@_);

    my $sub = sub {
        defined(blessed($_[0])) && $_[0] -> isa('Math::Complex')
          ? $_[0]
          : Math::Complex -> new($_[0]);
    };

    return $x -> sapply($sub);
}

# We need a transpose() method, since the transpose of a matrix with complex
# numbers also takes the conjugate of all elements.

sub transpose {
    my $x = shift;
    my $y = $x -> SUPER::transpose(@_);

    return $y -> sapply(sub { ~$_[0] });
}

# We need an as_string() method, since our parent's methods doesn't format
# complex numbers correctly.

sub as_string {
    my $self = shift;
    my $out = "";
    for my $row (@$self) {
        for my $elm (@$row) {
            $out = $out . sprintf "%10s ", $elm;
        }
        $out = $out . sprintf "\n";
    }
    $out;
}

1;
