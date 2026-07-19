package GraphQL::Houtou::Role::HashMappable;

use 5.014;
use strict;
use warnings;

use Role::Tiny;

# Utility helpers for hash-shaped GraphQL values and field maps.

sub hashmap {
  my ($self, $item, $source, $code) = @_;
  return $item if !defined $item;

  my @errors = map qq{In field "$_": Unknown field.\n},
    grep { !exists $source->{$_} } sort keys %$item;
  my %newvalue = map {
    my @pair = eval { ($_ => scalar $code->($_, $item->{$_})) };
    push @errors, qq{In field "$_": $@} if $@;
    exists $item->{$_} ? @pair : ();
  } sort keys %$source;

  die @errors if @errors;
  return \%newvalue;
}

1;
