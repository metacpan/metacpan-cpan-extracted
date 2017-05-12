#!/usr/bin/perl -T

# t/01meta.t
#  Tests that the META.yml meets the specification
#
# $Id: 99meta.t 8277 2009-07-29 02:54:25Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING}) {
  plan skip_all => 'Author tests not required for installation';
}

my %MODULES = (
  'Test::CPAN::Meta'  => 0.13,
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

plan tests => 2;

# counts as 2 tests
meta_spec_ok('META.yml', undef, 'META.yml matches the META-spec');
