#
# tied hash object that maintains two additional states:
#   1. a parallel hash table where all original keys and values
#      are run through  &Devel::DumpTrade::dump_scalar
#   2. a cache of results from  Text::Shorten::shorten_hash
#
# Calls to  Devel::DumpTrace::hash_repr  should not trigger calls
# to  Text::Shorten::shorten_hash  unless the hash table
# has been updated since the last  shorten_hash  call.
#

package Devel::DumpTrace::CachedDisplayedHash;

use strict;
use warnings;
use Carp;
our $VERSION = '0.26';

*dump_scalar = \&Devel::DumpTrace::dump_scalar;


sub TIEHASH {
  my ($class, @list) = @_;

  # HASH:  the original and primary hash table

  # PHASH: copy of HASH where all keys and values are
  #        filtered through Devel::DumpTrace::dump_scalar;

  # CACHE: store of results from Text::Shorten. Keys are
  #        auxiliary arguments to Text::Shorten::shorten_hash,
  #        values are array refs of shorten_hash return values.
  #        Cache is cleared when any element of the hash
  #        is changed.

  my $self = {
	      CACHE => {},
	      HASH => { @list },
	      PHASH => { map { dump_scalar($_) } @list }
	     };
  return bless $self, $class;
}

sub FETCH {
  my ($self, $key) = @_;
  return $self->{HASH}{$key};
}

sub STORE {
  my ($self, $key, $value) = @_;
  $self->clear_cache;
  my $old = $self->{HASH}{$key};
  $self->{HASH}{$key} = $value;
  $self->{PHASH}{dump_scalar($key)} = dump_scalar($value);
  return $old;
}

sub DELETE {
  my ($self, $key) = @_;
  $self->clear_cache;
  delete $self->{PHASH}{dump_scalar($key)};
  return delete $self->{HASH}{$key};
}

sub CLEAR {
  my $self = shift;
  $self->clear_cache;
  $self->{PHASH} = {};
  $self->{HASH} = {};
  return;
}

sub EXISTS {
  my ($self, $key) = @_;
  return exists $self->{HASH}{$key};
}

sub FIRSTKEY {
  my $self = shift;
  scalar keys %{$self->{HASH}};
  return each %{$self->{HASH}};
}

sub NEXTKEY {
  my ($self, $lastkey) = @_;
  return each %{$self->{HASH}};
}

sub SCALAR {
  my $self = shift;
  return scalar %{$self->{HASH}};
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
  if ($Devel::DumpTrace::HASHREPR_SORT) {
      my %h = @$value;
      $value = [ map { $_ => $h{$_} } sort keys %h ];
  }
  return;
}

sub get_cache {
  my ($self, $key) = @_;
  return $self->{CACHE}{$key};
}

sub is {
    my ($pkg, $hashref) = @_;
    return tied(%$hashref) && ref(tied(%$hashref)) eq $pkg;
}

1;
