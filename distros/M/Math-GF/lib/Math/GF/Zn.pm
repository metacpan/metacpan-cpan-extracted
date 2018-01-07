package Math::GF::Zn;
use strict;
use warnings;
{ our $VERSION = '0.004'; }

use Scalar::Util qw< blessed >;
use overload
  '/'  => 'divided_by',
  '==' => 'equal_to',
  'eq' => 'equal_to',
  '-'  => 'minus',
  '!=' => 'not_equal_to',
  '+'  => 'plus',
  '""' => 'stringify',
  '*'  => 'times',
  '**' => 'to_power';

use Ouch;
use Moo;

has field => (
   is => 'ro',
   required => 1,
   isa => sub {
      my $F = shift;
      (blessed($F) && $F->isa('Math::GF'))
        or ouch 500, 'field is not a valid Math::GF instance';
      $F->order_is_prime
        or ouch 500, 'cannot build Zn over non-prime n';
      return 1;
   },
);

# the "n" in "Zn"
has n => (
   is      => 'ro',
   init_arg => undef,
   lazy => 1,
   default => sub { shift->field->order },
);

# the value of this object
has v => (
   is      => 'ro',
   default => 0,
);

# the multiplicative inverse
has i => (
   is      => 'ro',
   lazy    => 1,
   builder => 'BUILD_multiplicative_inverse',
);

has o => (
   is => 'ro',
   lazy => 1,
   builder => 'BUILD_additive_inverse',
);

sub assert_compatibility {
   my ($self, $other) = @_;
   (blessed($other) && $other->isa('Math::GF::Zn'))
     || ouch 500, 'one of the operands is not a Math::GF::Zn object';
   my $n = $self->n;
   $n == $other->n
     || ouch 500, 'the two operands are not in the same field';
   return $n;
} ## end sub assert_compatibility

sub BUILD_multiplicative_inverse {
   my $self = shift;
   my $v    = $self->v or ouch 500, 'no inverse for 0';
   my $n    = $self->n;
   my ($i, $x) = (1, 0);
   for (1 .. $n - 1) {
      $x = ($x + $v) % $n;
      return $_ if $x == 1;
   }
   ouch 500, "no inverse for $v in Z_$n"; # never happens
} ## end sub BUILD_multiplicative_inverse

sub BUILD_additive_inverse {
   my $self = shift;
   return $self->n - $self->v;
}

sub divided_by {
   my ($self, $other, $swap) = @_;
   my $n = $self->assert_compatibility($other);
   ($self, $other) = ($other, $self) if $swap;    # never happens...
   return $self->new(
      field => $self->field,
      v => (($self->v * $other->i) % $n),
   );
} ## end sub divided_by

sub equal_to {
   my ($self, $other, $swap) = @_;
   my $n = $self->assert_compatibility($other);
   return $self->v == $other->v;
}

sub inv {
   my $self = shift;
   return $self->new(
      field => $self->field,
      v => $self->i,
      i => $self->v,
   );
}

sub minus {
   my ($self, $other, $swap) = @_;
   my $n = $self->assert_compatibility($other);
   return $self->new(
      field => $self->field,
      v => (($self->v - $other->v) % $n),
   );
} ## end sub minus

sub not_equal_to {
   return !shift->equal_to(@_);
}

sub opp {
   my $self = shift;
   return $self->new(
      field => $self->field,
      v => $self->o,
      o => $self->v,
   );
}

sub plus {
   my ($self, $other, $swap) = @_;
   my $n = $self->assert_compatibility($other);
   return $self->new(
      field => $self->field,
      v => (($self->v + $other->v) % $n),
   );
} ## end sub plus

sub stringify {
   return shift->v;
}

sub times {
   my ($self, $other, $swap) = @_;
   my $n = $self->assert_compatibility($other);
   return $self->new(
      field => $self->field,
      v => (($self->v * $other->v) % $n),
   );
} ## end sub times

sub to_power {
   my ($self, $exp, $swap) = @_;
   ouch 500, 'cannot elevate' if $swap;
   my ($n, $v, $x) = ($self->n, $self->v, 1);
   while ($exp > 0) {
      $x = ($x * $v) % $n or last;
      $exp--;
   }
   return $self->new(
      field => $self->field,
      v => $x,
   );
} ## end sub to_power

1;
