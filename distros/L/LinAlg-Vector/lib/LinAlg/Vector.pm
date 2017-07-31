##############################################################################
# Package/use statements
##############################################################################

package LinAlg::Vector;

use 5.006;
use strict;
use warnings;

use Math::Round q(:all);
use Moose;
use Params::Check::Item;

BEGIN {
  our $VERSION = '0.01';
}

##############################################################################
# class definition
##############################################################################

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;
  my @args = @_;

  if(scalar(@args) == 1 && ref($args[0]) eq "ARRAY") {
    my @arr = @{$args[0]};
    my @copy = @arr[0..$#arr];
    return $class->$orig(data=>\@copy);
  } else {
    return $class->$orig(@args);
  }
};

has _v => (
  is => "rw",
  isa => "ArrayRef[Num]",
  default => sub { [] },
  init_arg => "data"
);

sub raw {
  my ($self) = @_[0..0];
  my @copy = @{$self->_v}[0..$self->len-1];
  return \@copy;
}

sub toString {
  my ($self) = @_[0..0];
  return "[".(join(',', @{$self->_v}))."]";
}

sub len {
  my $self = shift;
  return scalar(@{$self->_v});
}

sub eq {
  my ($self, $b, $pow) = @_[0..2];
  checkClass($b, "LinAlg::Vector", "argument is not LinAlg::Vector");
  checkNumEQ($self->len, $b->len, "vectors are different lens");

  my $doRound = 0;
  my $roundTo = 1;
  if(defined($pow)) {
    checkIndex(abs($pow), "invalid power of 10 to round to");
    $doRound = 1;
    $roundTo = 10**($pow);
  }

  if($doRound) {
    for(my $i=0; $i<$self->len; $i++) {
      if(nearest($roundTo,$self->get($i)) != nearest($roundTo,$b->get($i))) {
        return 0;
      }
    }
  } else {
    for(my $i=0; $i<$self->len; $i++) {
      if($self->get($i) != $b->get($i)) {
        return 0;
      }
    }
  }
  return 1; 
}


sub get {
  my ($self, $num) = @_[0..1];
  checkNumber($num, "not number");
  checkNumLT($num, $self->len, "invalid vector index");

  return $self->_v->[$num];
}
  
#NOTE: cannot grow vector after created!
sub set {
  my ($self, $num, $val) = @_[0..2];
  checkNumber($num, "not number");
  checkNumber($val, "not number");
  checkNumLT($num, $self->len, "invalid vector index");

  return $self->_v->[$num] = $val;
}

sub copy {
  my $self = shift;
  my @newData = @{$self->_v}[0..$self->len-1];
  return LinAlg::Vector->new(data=>\@newData);
}


sub add {
  my ($self, $b) = @_[0..1];
  checkClass($b, "LinAlg::Vector", "argument is not LinAlg::Vector");
  checkNumEQ($self->len, $b->len, "vectors are different lens");

  my @newData = ();
  foreach my $i (0..$self->len-1) {
    push(@newData, $self->get($i)+$b->get($i))
  }
  return LinAlg::Vector->new(data=>\@newData);
}

sub subt {
  my ($self, $b) = @_[0..1];
  checkClass($b, "LinAlg::Vector", "argument is not LinAlg::Vector");
  checkNumEQ($self->len, $b->len, "vectors are different lens");

  my @newData = ();
  foreach my $i (0..$self->len-1) {
    push(@newData, $self->get($i) - $b->get($i))
  }
  return LinAlg::Vector->new(data=>\@newData);
}

sub dot {
  my ($self, $b) = @_[0..1];
  checkClass($b, "LinAlg::Vector", "argument is not LinAlg::Vector");
  checkNumEQ($self->len, $b->len, "vectors are different lens");

  my $sum = 0;
  foreach my $i (0..$self->len-1) {
    $sum += $self->get($i) * $b->get($i);
  }
  return $sum;
}

sub x { my $self = shift; return $self->get(0); }
sub y { my $self = shift; return $self->get(1); }
sub z { my $self = shift; return $self->get(2); }

sub cross {
  my ($self, $b) = @_[0..1];
  checkClass($b, "LinAlg::Vector", "argument is not LinAlg::Vector");
  checkNumEQ($self->len, $b->len, "vectors are different lens");
  checkNumEQ($self->len, 3, "can only cross-product 3-dim vectors");

  my $x = $self->y*$b->z - $self->z*$b->y;
  my $y = $self->z*$b->x - $self->x*$b->z;
  my $z = $self->x*$b->y - $self->y*$b->x;
  return LinAlg::Vector->new(data=>[$x, $y, $z]);
}

sub scale {
  my ($self, $b) = @_[0..1];
  checkNumber($b, "argument is not number");

  my @newData = ();
  foreach my $i (0..$self->len-1) {
    push(@newData, $self->get($i)*$b);
  }
  return LinAlg::Vector->new(data=>\@newData);
}

sub mag {
  my ($self) = @_[0..0];
  return sqrt($self->dot($self));
}

sub unit {
  my ($self) = @_[0..0];
  return $self->scale(1/$self->mag());
}

sub proj {
  my ($self, $b) = @_[0..1];
  checkClass($b, "LinAlg::Vector", "argument is not LinAlg::Vector");
  checkNumEQ($self->len, $b->len, "vectors are different lens");
  return $b->unit()->scale($self->dot($b)/$b->mag());
}

sub rotate {
  checkImpl("LinAlg::Vector::rotate");
}

##############################################################################
# Add interfaces and end class definition
##############################################################################

no Moose;
__PACKAGE__->meta->make_immutable;

1; # End of Params::Check::Item

##############################################################################
# Perldoc 
##############################################################################

=head1 NAME

LinAlg::Vector - Extensive vector library based on Moose class system.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

LinAlg::Vector proveds an object-oriented interface for creating and using 
vectors composed of numbers. It supports most mathematical functions such
as add, subtract, dot, cross, scale, unit, and projection. Additionally,
convenience functions for comparing vectors, and stringifying them are
also provided.

All vector methods, except for C<set>, will not modify the underlying 
vector -- they all will return new vectors.

An example of performing the triple-product of three vectors:

    use LinAlg::Vector;

    my $v1 = LinAlg::Vector->new([1,2,3]);
    my $v2 = LinAlg::Vector->new([4,5,6]);
    my $v3 = LinAlg::Vector->new([7,8,9]);
    my $s1 = $v1->dot($v2->cross($v3));

=head1 CONSTRUCTOR

The constructor takes in either a hash or an Array reference. The only
valid key-val pair in the hash is C<data=>[]>. Examples of using the
constructor are:
  
  LinAlg::Vector->new(data=>[1,2,3]);
  LinAlg::Vector->new([1,2,3]);

=head1 METHODS

=head2 raw

returns a copy of the underlying data array. If you manipulate the 
returned copy, it will not affect the original vector data.

=head2 toString

returns a stringified version of the vector

=head2 len

returns the length of the vector

=head2 eq VEC2,[PRECISION]

returns 1 if this vector is equivalent to VEC2 (same length and
element values are all the same). Optinally, you can pass in PRECISION,
which can fine-tune what power-of-10 you round elements to when comparing.
Examples are:

  my $v1 = LinAlg::Vector->new([1,2]);
  my $v2 = LinAlg::Vector->new([1.001,1.999]);
  $v1->eq($v2);       #returns 0
  $v1->eq($v2, -2);   #rounds each element to nearest 10**-2. returns 1

=head2 get IDX
  
returns the element at index IDX. Zero-indexed.

=head2 set IDX,VAL

sets the element VAL at index IDX. Zero-indexed. retuns the value just set.

=head2 copy

returns copy of LinAlg::Vector, with a copy of the underlying data as well.

=head2 add VEC2

adds VEC2 to this vector and returns a new vector.

=head2 subt VEC2

subtracts VEC2 from this vector and returns a new vector.

=head2 dot VEC2

performs a dot-product with this vector and VEC2 and returns the scalar.

=head2 x

returns C<get(0)>

=head2 y

returns C<get(1)>

=head2 z

returns C<get(2)>

=head2 cross VEC2

performs cross-product with VEC2 and returns result vector. The operation
is 'this' x VEC2. If 'this' and VEC2 are not of length 3, an error is thrown.

=head2 scale NUM

scales this vector by NUM and returns new vector.

=head2 mag

returns the magnitude of this vector: sqrt(this->dot(this))

=head2 unit

returns the unit vector for this vector: this->scale(1/this->mag)

=head2 proj VEC2

returns the projected vector of this vector onto VEC2.

=head2 rotate

Not Yet Implemented

=head1 SEE ALSO

  LinAlg::Matrix

=head1 AUTHOR

Samuel Steffl, C<sam@ssteffl.com>

=head1 BUGS

Please report any bugs or feature requests through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LinAlg-Vector>.
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc LinAlg::Matrix

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Samuel Steffl.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

