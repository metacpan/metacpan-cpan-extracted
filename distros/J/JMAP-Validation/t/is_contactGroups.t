#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Validation::Checks::ContactGroup;
use JMAP::Validation::Generators::ContactGroup;
use Test2::Bundle::Extended;

my @notFound = (
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
);

foreach my $list ([JMAP::Validation::Generators::ContactGroup::generate()], []) {
  foreach my $notFound ([@notFound], undef) {
    is(
      {
        accountId => JMAP::Validation::Generators::String->generate(),
        state     => JMAP::Validation::Generators::String->generate(),
        list      => $list,
        notFound  => $notFound,
      },
      $JMAP::Validation::Checks::ContactGroup::is_contactGroups,
    );
  }
}

done_testing();
