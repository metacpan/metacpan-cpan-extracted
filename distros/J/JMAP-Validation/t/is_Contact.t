#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Validation::Checks::Contact;
use JMAP::Validation::Generators::Contact;
use Test2::Bundle::Extended;

foreach my $Contact (JMAP::Validation::Generators::Contact::generate()) {
  is(
    $Contact,
    $JMAP::Validation::Checks::Contact::is_Contact,
  );
}

done_testing();
