#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Validation::Checks::File;
use JMAP::Validation::Generators::File;
use Test2::Bundle::Extended;

foreach my $File (JMAP::Validation::Generators::File::generate()) {
  is(
    $File,
    $JMAP::Validation::Checks::File::is_File,
  );
}

done_testing();
