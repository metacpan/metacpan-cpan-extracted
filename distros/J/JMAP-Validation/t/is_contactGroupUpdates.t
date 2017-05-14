#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Validation::Checks::ContactGroup;
use JMAP::Validation::Generators::String;
use Test2::Bundle::Extended;

my @changed = (
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
);

my @removed = (
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
);

foreach my $changed ([@changed], []) {
  foreach my $removed ([@removed], []) {
    is(
      {
        accountId => JMAP::Validation::Generators::String->generate(),
        oldState  => JMAP::Validation::Generators::String->generate(),
        newState  => JMAP::Validation::Generators::String->generate(),
        changed   => $changed,
        removed   => $removed,
      },
      $JMAP::Validation::Checks::ContactGroup::is_contactGroupUpdates,
    );
  }
}

done_testing();
