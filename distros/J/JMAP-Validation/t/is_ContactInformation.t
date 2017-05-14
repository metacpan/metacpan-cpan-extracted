#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Validation::Checks::ContactInformation;
use JMAP::Validation::Generators::ContactInformation;
use Test2::Bundle::Extended;

my %ContactInformation_types = (
  emails => $JMAP::Validation::Checks::ContactInformation::is_ContactInformation_emails,
  phones => $JMAP::Validation::Checks::ContactInformation::is_ContactInformation_phones,
  online => $JMAP::Validation::Checks::ContactInformation::is_ContactInformation_online,
);

foreach my $type (keys %ContactInformation_types) {
  my @ContactInformation_type = JMAP::Validation::Generators::ContactInformation::generate($type);

  foreach my $ContactInformation ([@ContactInformation_type], []) {
    is(
      $ContactInformation,
      $ContactInformation_types{$type},
    );
  }
}

done_testing();
