#!/usr/bin/perl -T

# t/01pod-coverage.t
#  Ensures all subroutines are documented with POD
#
# $Id: 01pod-coverage.t 8235 2009-07-26 02:57:24Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
  plan skip_all => 'Author tests not required for installation';
}

my %MODULES = (
  'Test::Pod::Coverage' => 1.04,
);

# Module::CPANTS::Kwalitee won't detect that we're using test modules as
# author tests, so we convince it that we're loading it in the normal way.
0 and require Test::Pod::Coverage;

while (my ($module, $version) = each %MODULES) {
  eval "use $module $version";
  next unless $@;

  if ($ENV{RELEASE_TESTING}) {
    die 'Could not load release-testing module ' . $module;
  }
  else {
    plan skip_all => $module . ' not available for testing';
  }
}

all_pod_coverage_ok();
