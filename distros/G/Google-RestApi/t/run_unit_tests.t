#!/usr/bin/env perl

# run this with 'prove -v run_unit_tests' to run them all in verbose mode.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";   # the rest::api code
use lib "$FindBin::RealBin/lib";      # the support code for these tests.

use Test::Class::Load "$FindBin::RealBin/unit";

Test::Class->runtests();
