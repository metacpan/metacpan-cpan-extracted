#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use lib '.';
use inc::Module::Install;

die "This module is known to exercise a bug in 5.6.0. Please upgrade your perl.\n" if $] eq '5.006';

all_from('lib/Getargs/Long.pm');

auto_set_bugtracker;
githubmeta;

configure_requires(
  # Module::Install::Bugtracker needs this
  'URI::Escape' => 0,
);

requires(
  'Log::Agent' => '0.105',
);

test_requires(
  'Test::More' => 0,
);

license 'perl';
auto_license(holder => 'David Coppit');

no_index 'directory' => 'private-lib';

enable_verbose_cpan_testing();

use_standard_tests;

WriteAll();
