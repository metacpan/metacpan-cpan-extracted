#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Validation::Checks::Contact;
use JMAP::Validation::Generators::String;
use JSON::PP;
use Test2::Bundle::Extended;

my @changed = (
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
);

my @removed = (
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
);

foreach my $hasMoreUpdates (JSON::PP::true, JSON::PP::false) {
  foreach my $changed ([@changed], []) {
    foreach my $removed ([@removed], []) {
      is(
        {
          accountId      => JMAP::Validation::Generators::String->generate(),
          oldState       => JMAP::Validation::Generators::String->generate(),
          newState       => JMAP::Validation::Generators::String->generate(),
          hasMoreUpdates => $hasMoreUpdates,
          changed        => $changed,
          removed        => $removed,
        },
        $JMAP::Validation::Checks::Contact::is_contactUpdates,
      );
    }
  }
}

done_testing();
