package JMAP::Validation::Tests::Contact;

use strict;
use warnings;

use JMAP::Validation::Tests::Address;
use JMAP::Validation::Tests::Array;
use JMAP::Validation::Tests::Boolean;
use JMAP::Validation::Tests::ContactInformation;
use JMAP::Validation::Tests::File;
use JMAP::Validation::Tests::Object;
use JMAP::Validation::Tests::String;

sub is_Contact {
  my ($value) = @_;

  return unless JMAP::Validation::Tests::Object::is_object($value);
  return unless JMAP::Validation::Tests::String::is_id($value->{id});
  return unless JMAP::Validation::Tests::Boolean::is_boolean($value->{isFlagged});

  if (defined $value->{avatar}) {
    return unless JMAP::Validation::Tests::File::is_File($value->{avatar});
  }

  my @string_types = qw{
    prefix
    firstName
    lastName
    suffix
    nickname
    company
    department
    jobTitle
    notes
  };

  foreach my $field (@string_types) {
    return unless JMAP::Validation::Tests::String::is_string($value->{$field});
  }

  return unless JMAP::Validation::Tests::String::is_date($value->{birthday});
  return unless JMAP::Validation::Tests::String::is_date($value->{anniversary});

  foreach my $ContactInformation_type (qw{emails phones online}) {
    return unless JMAP::Validation::Tests::Array::is_array($value->{$ContactInformation_type});

    my $method = "JMAP::Validation::Tests::ContactInformation::is_ContactInformation_$ContactInformation_type";
    $method    =~ s/s$//;

    foreach my $ContactInformation (@{$value->{$ContactInformation_type}}) {
      no strict 'refs';
      return unless $method->($ContactInformation);
    }
  }

  return unless JMAP::Validation::Tests::Array::is_array($value->{addresses});

  foreach my $address (@{$value->{addresses}}) {
    return unless JMAP::Validation::Tests::Address::is_Address($address);
  }
  return 1;
}

1;
