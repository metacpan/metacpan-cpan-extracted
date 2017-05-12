#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::Manifest qw(manifind manicheck filecheck);
use Test::More tests => 3;
use Test::NoWarnings;

# Make sure we're on the developer's system
-e 'MANIFEST'
  or BAIL_OUT("Can't find the MANIFEST file");


# Check the manifest is accurate
{
  local $ExtUtils::Manifest::Quiet=1;

  my @missing=manicheck();
  ok(!@missing,'manicheck')
    or diag "    Files listed in MANIFEST not found: @missing";

  my @extra=filecheck();
  ok(!@extra,'filecheck')
    or diag "    Files not listed in MANIFEST: @extra";
}


