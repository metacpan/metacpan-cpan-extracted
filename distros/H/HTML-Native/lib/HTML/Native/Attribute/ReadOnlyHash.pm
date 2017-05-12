package HTML::Native::Attribute::ReadOnlyHash;

use Carp;
use strict;
use warnings;

sub new {
  my $old = shift;
  $old = tied ( %$old ) // $old if ref $old;
  my $class = ref $old || $old;
  my $self = shift;

  my $hash;
  tie %$hash, $class, $self;
  bless $hash, $class;
  return $hash;
}

sub TIEHASH {
  my $old = shift;
  my $class = ref $old || $old;
  my $data = shift || {};

  # Do not bless the reference that is passed in; the whole point is
  # not to modify the underlying data
  my $self = \$data;
  bless $self, $class;

  return $self;
}

sub FETCH {
  my $self = shift;
  my $key = shift;

  return $$self->{$key};
}

sub STORE {
  my $self = shift;
  my $key = shift;
  my $value = shift;

  croak "Cannot modify read-only hash";
}

sub DELETE {
  my $self = shift;
  my $key = shift;

  croak "Cannot modify read-only hash";
}

sub CLEAR {
  my $self = shift;

  croak "Cannot modify read-only hash";
}

sub EXISTS {
  my $self = shift;
  my $key = shift;

  return exists $$self->{$key};
}

sub FIRSTKEY {
  my $self = shift;

  keys %$$self;
  return each %$$self;
}

sub NEXTKEY {
  my $self = shift;

  return each %$$self;
}

sub SCALAR {
  my $self = shift;

  return scalar %$$self;
}

1;
