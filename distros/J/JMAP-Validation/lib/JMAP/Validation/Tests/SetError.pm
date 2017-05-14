package JMAP::Validation::Tests::SetError;

use strict;
use warnings;

use JMAP::Validation::Tests::Object;
use JMAP::Validation::Tests::String;

sub is_SetError {
  my ($value) = @_;

  return unless JMAP::Validation::Tests::Object::is_object($value);
  return unless JMAP::Validation::Tests::String::is_string($value->{type});

  return 1 unless defined $value->{description};
  return JMAP::Validation::Tests::String::is_string($value->{description});
}

sub is_SetError_invalidProperties {
  my ($value, @valid_properties) = @_;

  return unless is_SetError($value);
  return unless $value->{type} eq 'invalidProperties';

  my %valid_properties
    = map { $_ => 1 }
        @valid_properties;

  if (defined $value->{properties}) {
    return unless JMAP::Validation::Tests::Array::is_array($value->{properties});

    foreach my $property (@{$value->{properties}}) {
      return unless $valid_properties{$property};
    }
  }

  return 1;
}

sub is_SetError_notFound {
  my ($value) = @_;

  return unless is_SetError($value);
  return unless $value->{type} eq 'notFound';

  return 1;
}

1;
