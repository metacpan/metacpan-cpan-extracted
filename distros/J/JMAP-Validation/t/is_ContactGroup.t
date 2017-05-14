#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Validation::Checks::ContactGroup;
use JMAP::Validation::Generators::ContactGroup;
use Test2::Bundle::Extended;

foreach my $ContactGroup (JMAP::Validation::Generators::ContactGroup::generate()) {
  is(
    $ContactGroup,
    $JMAP::Validation::Checks::ContactGroup::is_ContactGroup,
  );
}

done_testing();
