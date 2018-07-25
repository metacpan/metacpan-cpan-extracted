#
# tied array object that maintains two additional states:
#   1. a parallel array where all original entries
#      are run through  &Devel::DumpTrade::dump_scalar
#   2. a cache of results from  Text::Shorten::shorten_array
#
# Calls to  Devel::DumpTrace::array_repr  should not trigger calls
# to  Text::Shorten::shorten_array  unless the array
# has been updated since the last  shorten_array  call.
#

package Devel::DumpTrace::CachedDisplayedArray;

use strict;
use warnings;
use Carp;
our $VERSION = '0.27';

*dump_scalar = \&Devel::DumpTrace::dump_scalar;


sub TIEARRAY {
  my ($class, @list) = @_;

  # ARRAY:  the original and primary hash table

  # PARRAY: copy of HASH where all keys and values are
  #         filtered through Devel::DumpTrace::dump_scalar;

  # CACHE:  store of results from Text::Shorten. Keys are
  #         auxiliary arguments to Text::Shorten::shorten_array,
  #         values are array refs of shorten_array return values.
  #         Cache is cleared when any element of the array
  #         is changed.

  my $self = {
	      CACHE => {},
	      ARRAY => [ @list ],
	      PARRAY => [ map { dump_scalar($_) } @list ]
	     };
  return bless $self, $class;
}

sub FETCH {
  my ($self, $index) = @_;
  return $self->{ARRAY}[$index];
}

sub STORE {
  my ($self, $index, $value) = @_;
  $self->clear_cache;
  my $old = $self->{ARRAY}[$index];
  $self->{ARRAY}[$index] = $value;
  $self->{PARRAY}[$index] = dump_scalar($value);
  return $old;
}

sub FETCHSIZE {
  my $self = shift;
  return scalar @{$self->{ARRAY}};
}

sub STORESIZE {
  my ($self, $newcount) = @_;
  my $oldcount = $self->FETCHSIZE();
  if ($newcount > $oldcount) {
    $self->clear_cache;
    $self->STORE($_, undef) for $oldcount .. $newcount-1;
  } elsif ($newcount < $oldcount) {
    $self->clear_cache;
    $self->POP() for $newcount .. $oldcount-1;
  }
  return;
}

sub EXTEND {
  return;
}

sub DELETE {
  my ($self, $index) = @_;
  $self->clear_cache;
  return $self->STORE($index, undef);
}

sub CLEAR {
  my $self = shift;
  $self->clear_cache;
  $self->{PARRAY} = [];
  $self->{ARRAY} = [];
  return;
}

sub EXISTS {
  my ($self, $index) = @_;
  return exists $self->{ARRAY}[$index];
}

sub PUSH {
  my ($self, @list) = @_;
  if (@list > 0) {
    $self->clear_cache;
  }
  push @{$self->{ARRAY}}, @list;
  push @{$self->{PARRAY}}, map { dump_scalar($_) } @list;
  return $self->FETCHSIZE();
}

sub POP {
  my $self = shift;
  if (@{$self->{ARRAY}} > 0) {
    $self->clear_cache;
  }
  pop @{$self->{PARRAY}};
  return pop @{$self->{ARRAY}};
}

sub SHIFT {
  my $self = shift;
  if (@{$self->{ARRAY}} > 0) {
    $self->clear_cache;
  }
  shift @{$self->{PARRAY}};
  return shift @{$self->{ARRAY}};
}

sub UNSHIFT {
  my ($self, @list) = @_;
  if (@list > 0) {
    $self->clear_cache;
  }
  unshift @{$self->{PARRAY}}, map { dump_scalar($_) } @list;
  my $result = unshift @{$self->{ARRAY}}, @list;
  return $result;
}

sub SPLICE {
  my ($self, $offset, $length, @list) = @_;
  $offset ||= 0;
  $length ||= $self->FETCHSIZE() - $offset;

  $self->clear_cache;
  splice @{$self->{PARRAY}}, $offset, $length, map { dump_scalar($_) } @list;
  return splice @{$self->{ARRAY}}, $offset, $length, @list;
}

# sub UNTIE { } # not implemented
# sub DESTROY { } # not implemented

sub clear_cache {
  my $self = shift;
  $self->{CACHE} = {};
  return;
}

sub store_cache {
  my ($self, $key, $value) = @_;
  $self->{CACHE}{$key} = $value;
  return;
}

sub get_cache {
  my ($self, $key) = @_;
  return $self->{CACHE}{$key};
}

sub is {
    my ($pkg, $arrayref) = @_;
    return tied(@$arrayref) && ref(tied(@$arrayref)) eq $pkg;
}

1;
