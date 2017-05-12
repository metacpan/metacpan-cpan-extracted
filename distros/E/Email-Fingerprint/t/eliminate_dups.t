#!/usr/bin/perl
# Test the eliminate_dups app class

# Test::Trap is severely broken, so we're reduced to this disgusting
# expedient.

use strict;
use warnings;

# Check for Test::Trap *and* its improperly-handled prerequisite.
use Test::More;
eval "use Data::Dump; use Test::Trap";
plan skip_all => "You need Data::Dump and Test::Trap to test the application" if $@;

# Run the rest of the test from a separate file, because Test::Trap
# doesn't work when loaded *with* an eval, but it crashes the test script
# if it's loaded *without* an eval. Sigh.
require "t/eliminate_dups.pl";
