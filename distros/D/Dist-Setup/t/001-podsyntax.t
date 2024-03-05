# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

#!/usr/bin/perl

use strict;
use warnings;

use English;
use FindBin;
use Test2::V0;
use Readonly;

our $VERSION = 0.01;

BEGIN {
  if ($ENV{HARNESS_ACTIVE} && !$ENV{EXTENDED_TESTING}) {
    skip_all('Extended test. Run manually or set $ENV{EXTENDED_TESTING} to a true value to run.');
  }
}

# Ensure a recent version of Test::Pod is present
BEGIN {
  Readonly my $TEST_POD_VERSION => 1.22;
  eval "use Test::Pod ${TEST_POD_VERSION}";  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  if ($EVAL_ERROR) {
    skip_all("Test::Pod ${TEST_POD_VERSION} required for testing POD");
  }
}

my @dirs;

sub add_if_exists {
  return push @dirs, $_[0] if -d $_[0];
  return;
}

if (!add_if_exists("${FindBin::Bin}/../blib")) {
  add_if_exists("${FindBin::Bin}/../lib");
}
add_if_exists("${FindBin::Bin}/../script");
my @files = all_pod_files(@dirs);
my $nb_files = @files;
diag("Testing $nb_files POD files.");

all_pod_files_ok(@files);

# End of the template. You can add custom content below this line.
