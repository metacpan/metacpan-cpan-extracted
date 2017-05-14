#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Validation::Checks::Address;
use JMAP::Validation::Generators::Address;
use Test2::Bundle::Extended;

foreach my $Address (JMAP::Validation::Generators::Address::generate()) {
  is(
    $Address,
    $JMAP::Validation::Checks::Address::is_Address,
  );
}

done_testing();
