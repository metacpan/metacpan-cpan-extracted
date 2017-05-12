#!/usr/bin/perl

# t/99kwalitee.t
#  Uses the CPANTS Kwalitee metrics to test the distribution
#
# $Id: 99kwalitee.t 8277 2009-07-29 02:54:25Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
  plan skip_all => 'Author tests not required for installation';
}

my %MODULES = (
  'Test::Kwalitee'          => 1.01,
  'Module::CPANTS::Analyse' => 0.85,
);

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
