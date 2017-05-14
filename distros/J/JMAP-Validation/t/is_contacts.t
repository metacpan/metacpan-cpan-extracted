#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Validation::Checks::Contact;
use JMAP::Validation::Generators::Contact;
use JMAP::Validation::Generators::String;
use Test2::Bundle::Extended;

my @notFound = (
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
);

foreach my $list ([JMAP::Validation::Generators::Contact::generate()], []) {
  foreach my $notFound ([@notFound], undef) {
    is(
      {
        accountId => JMAP::Validation::Generators::String->generate(),
        state     => JMAP::Validation::Generators::String->generate(),
        list      => $list,
        notFound  => $notFound,
      },
      $JMAP::Validation::Checks::Contact::is_contacts,
    );
  }
}

done_testing();
