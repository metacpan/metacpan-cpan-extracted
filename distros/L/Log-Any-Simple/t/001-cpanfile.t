# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

#!/usr/bin/perl

use strict;
use warnings;

use English;
use Test::CPANfile;
use Test2::V0;

our $VERSION = 0.02;

BEGIN {
  if ($ENV{HARNESS_ACTIVE} && !$ENV{EXTENDED_TESTING}) {
    skip_all('Extended test. Run manually or set $ENV{EXTENDED_TESTING} to a true value to run.');
  }
}

BEGIN {
  # This module seems to have trouble installing on some platform, so it’s
  # optional in the cpanfile and we skip the test if it’s not installed.
  eval 'use CPAN::Common::Index::Mux::Ordered';  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  if ($EVAL_ERROR) {
    skip_all('CPAN::Common::Index::Mux::Ordered required to validate the CPAN file');
  }
}

cpanfile_has_all_used_modules(
  perl_version => 5.024,
  develop => 1,
  suggests => 1,
  index => CPAN::Common::Index::Mux::Ordered->assemble(
    MetaDB => {},
    Mirror => {},
  ));

done_testing;

# End of the template. You can add custom content below this line.
