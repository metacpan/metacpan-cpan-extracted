package JMAP::Validation::Tests::ContactGroup;

use strict;
use warnings;

use JMAP::Validation::Tests::Array;
use JMAP::Validation::Tests::Object;
use JMAP::Validation::Tests::String;

sub is_ContactGroup {
  my ($value) = @_;

  return unless JMAP::Validation::Tests::Object::is_object($value);
  return unless JMAP::Validation::Tests::String::is_id($value->{id});

  return unless
       JMAP::Validation::Tests::String::is_string($value->{name})
    && JMAP::Validation::Tests::String::has_at_least_one_character($value->{name})
    && JMAP::Validation::Tests::String::has_at_most_256_bytes($value->{name});

  return unless JMAP::Validation::Tests::String::is_array_of_ids($value->{contactIds});

  return 1;
}

1;
