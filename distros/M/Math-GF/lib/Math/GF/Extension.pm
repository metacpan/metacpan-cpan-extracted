package Math::GF::Extension;
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
      return 1;
   },
);

has p => (
   is => 'ro',
   init_arg => undef,
   lazy => 1,
   default => sub { shift->field->p },
);

has n => (
   is => 'ro',
   init_arg => undef,
   lazy => 1,
   default => sub { shift->field->n },
);

has sum_table => (
   is => 'ro',
   init_arg => undef,
   lazy => 1,
   default => sub { shift->field->sum_table },
);

has prod_table => (
   is => 'ro',
   init_arg => undef,
   lazy => 1,
   default => sub { shift->field->prod_table },
);

# the identifier of this object
has v => (
   is      => 'ro',
   default => 0,
);

# the multiplicative inverse, if exists, undef otherwise
has i => (
   is      => 'ro',
   lazy    => 1,
   builder => 'BUILD_multiplicative_inverse',
);

has o => (
   is      => 'ro',
   lazy    => 1,
   builder => 'BUILD_additive_inverse',
);

sub assert_compatibility {
   my ($self, $other) = @_;
   (blessed($other) && $other->isa('Math::GF::Extension'))
     || ouch 500, 'one of the ops is not a Math::GF::Extension object';
   my $order = $self->field->order;
   $order == $other->field->order
     || ouch 500, 'the two operands are not in the same field';
   return $order;
}

sub BUILD_multiplicative_inverse {
   my $self = shift;
   my $v    = $self->v or ouch 500, 'no inverse for 0';
   my $pt = $self->prod_table;
   for my $i (0 .. $v) {
      return $i if $pt->[$v][$i] == 1;
   }
   for my $j (($v + 1) .. $#$pt) {
      return $j if $pt->[$j][$v] == 1;
   }
   my ($p, $n) = ($self->p, $self->n);
   ouch 500, "no inverse for $v in GF_${p}_$n"; # never happens
} ## end sub BUILD_multiplicative_inverse

sub BUILD_additive_inverse {
   my $self = shift;
   my $v    = $self->v or return 0;
   my $pt = $self->sum_table;
   for my $i (0 .. $v) {
      return $i if $pt->[$v][$i] == 0;
   }
   for my $j (($v + 1) .. $#$pt) {
      return $j if $pt->[$j][$v] == 0;
   }
   my ($p, $n) = ($self->p, $self->n);
   ouch 500, "no opposite for $v in GF_${p}_$n"; # never happens
}

sub _prod {
   my ($self, $x, $y) = @_;
   return $x > $y
     ? $self->prod_table->[$x][$y]
     : $self->prod_table->[$y][$x];
}

sub _sum {
   my ($self, $x, $y) = @_;
   return $x > $y
     ? $self->sum_table->[$x][$y]
     : $self->sum_table->[$y][$x];
}

sub divided_by {
   my ($self, $other, $swap) = @_;
   $self->assert_compatibility($other);
   ($self, $other) = ($other, $self) if $swap;    # never happens...
   return $self->new(
      field => $self->field,
      v => $self->_prod($self->v, $other->i),
   );
} ## end sub divided_by

sub equal_to {
   my ($self, $other, $swap) = @_;
   $self->assert_compatibility($other);
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

sub minus { # FIXME
   my ($self, $other, $swap) = @_;
   $self->assert_compatibility($other);
   return $self->new(
      field => $self->field,
      v => $self->_sum($self->v, $other->o),
   );
} ## end sub minus

sub not_equal_to {
   return !shift->equal_to(@_);
}

sub plus {
   my ($self, $other, $swap) = @_;
   my $n = $self->assert_compatibility($other);
   return $self->new(
      field => $self->field,
      v => $self->_sum($self->v, $other->v),
   );
} ## end sub plus

sub stringify {
   return shift->v;
}

sub times {
   my ($self, $other, $swap) = @_;
   $self->assert_compatibility($other);
   return $self->new(
      field => $self->field,
      v => $self->_prod($self->v, $other->v),
   );
} ## end sub times

sub to_power {
   my ($self, $exp, $swap) = @_;
   ouch 500, 'cannot elevate' if $swap;
   my $x = $self->field->multiplicative_neutral;
   my $zero = $self->field->additive_neutral;
   while ($exp > 0) {
      $x = $x * $self;
      last if $x == $zero;
      $exp--;
   }
   return $x;
} ## end sub to_power

1;
