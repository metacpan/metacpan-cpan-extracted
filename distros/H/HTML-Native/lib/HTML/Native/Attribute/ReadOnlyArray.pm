package HTML::Native::Attribute::ReadOnlyArray;

use Carp;
use strict;
use warnings;

sub new {
  my $old = shift;
  $old = tied ( @$old ) // $old if ref $old;
  my $class = ref $old || $old;
  my $self = shift || [];

  my $array;
  tie @$array, $class, $self;
  bless $array, $class;
  return $array;
}

sub TIEARRAY {
  my $old = shift;
  my $class = ref $old || $old;
  my $data = shift || [];

  # Do not bless the reference that is passed in; the whole point is
  # not to modify the underlying data
  my $self = \$data;
  bless $self, $class;

  return $self;
}

sub FETCH {
  my $self = shift;
  my $index = shift;

  return $$self->[$index];
}

sub STORE {
  my $self = shift;
  my $index = shift;
  my $value = shift;

  croak "Cannot modify read-only array";
}

sub FETCHSIZE {
  my $self = shift;

  return scalar @$$self;
}

sub STORESIZE {
  my $self = shift;
  my $count = shift;

  croak "Cannot modify read-only array";
}

sub EXTEND {
  my $self = shift;
  my $count = shift;

  croak "Cannot modify read-only array";
}

sub EXISTS {
  my $self = shift;
  my $index = shift;

  return exists $$self->[$index];
}

sub DELETE {
  my $self = shift;
  my $index = shift;

  croak "Cannot modify read-only array";
}

sub CLEAR {
  my $self = shift;

  croak "Cannot modify read-only array";
}

sub PUSH {
  my $self = shift;
  my @list = @_;

  croak "Cannot modify read-only array";
}

sub POP {
  my $self = shift;

  croak "Cannot modify read-only array";
}

sub SHIFT {
  my $self = shift;

  croak "Cannot modify read-only array";
}

sub UNSHIFT {
  my $self = shift;
  my @list = @_;

  croak "Cannot modify read-only array";
}

sub SPLICE {
  my $self = shift;
  my $offset = shift;
  my $length = shift;
  my @list = @_;

  croak "Cannot modify read-only array";
}

1;
