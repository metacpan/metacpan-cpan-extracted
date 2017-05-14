package JMAP::Validation::Tests::File;

use strict;
use warnings;

use JMAP::Validation::Tests::Number;
use JMAP::Validation::Tests::Object;
use JMAP::Validation::Tests::String;

sub is_File {
  my ($value) = @_;

  return unless JMAP::Validation::Tests::Object::is_object($value);
  return unless JMAP::Validation::Tests::String::is_id($value->{blobId});

  foreach my $field (qw{type name}) {
    if (defined $value->{$field}) {
      return unless JMAP::Validation::Tests::String::is_string($value->{$field});
    }
  }

  if (defined $value->{number}) {
    return unless JMAP::Validation::Tests::Number::is_number($value->{number});
  }

  return 1;
}

1;
