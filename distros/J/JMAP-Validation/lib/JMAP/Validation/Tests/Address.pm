package JMAP::Validation::Tests::Address;

use strict;
use warnings;

use JMAP::Validation::Tests::Boolean;
use JMAP::Validation::Tests::Object;
use JMAP::Validation::Tests::String;

sub is_Address {
  my ($value) = @_;

  return unless JMAP::Validation::Tests::Object::is_object($value);

  return unless JMAP::Validation::Tests::String::is_string($value->{type});
  return unless $value->{type} =~ qr{^(?:home|work|billing|postal|other)$};

  foreach my $field (qw{street locality region postcode country}) {
    return unless JMAP::Validation::Tests::String::is_string($value->{$field});
  }

  return unless JMAP::Validation::Tests::Boolean::is_boolean($value->{isDefault});

  return 1;
}

1;
