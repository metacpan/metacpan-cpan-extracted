#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use inc::Module::Install;

die "This module is known to exercise a bug in 5.6.0. Please upgrade your perl.\n" if $] eq '5.006';

all_from('lib/Getargs/Long.pm');

auto_set_bugtracker;
githubmeta;

requires(
  'Log::Agent' => '0.105',
);

test_requires(
  'Test::More' => 0,
);

license 'perl';
auto_license(holder => 'David Coppit');

enable_verbose_cpan_testing();

WriteAll();
