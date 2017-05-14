package JMAP::Validation::Tests::ContactInformation;

use strict;
use warnings;

use JMAP::Validation::Tests::Boolean;
use JMAP::Validation::Tests::Object;
use JMAP::Validation::Tests::String;

sub is_ContactInformation {
  my ($value) = @_;

  return unless JMAP::Validation::Tests::Object::is_object($value);

  return unless JMAP::Validation::Tests::String::is_string($value->{type});
  return unless $value->{type} =~ qr{fax|home|mobile|other|pager|personal|uri|username|work};

  if (defined $value->{label}) {
    return unless JMAP::Validation::Tests::String::is_string($value->{label});
  }

  return unless JMAP::Validation::Tests::String::is_string($value->{value});
  return unless JMAP::Validation::Tests::Boolean::is_boolean($value->{isDefault});

  return 1;
}

sub is_ContactInformation_email {
  my ($value) = @_;

  return unless is_ContactInformation($value);
  return unless $value->{type} =~ qr{personal|work|other};

  return 1;
}

sub is_ContactInformation_phone {
  my ($value) = @_;

  return unless is_ContactInformation($value);
  return unless $value->{type} =~ qr{home|work|mobile|fax|pager|other};

  return 1;
}

sub is_ContactInformation_online {
  my ($value) = @_;

  return unless is_ContactInformation($value);
  return unless $value->{type} =~ qr{uri|username|other};

  return 1;
}

1;
