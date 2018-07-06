#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use lib '.';
use inc::Module::Install;

all_from('lib/FileHandle/Unget.pm');

auto_set_bugtracker;
githubmeta;

requires(
  'Scalar::Util' => '1.14',
);

test_requires(
  'File::Slurp' => 0,
  'Test::More' => 0,
  'File::Spec::Functions' => 0,
);

license 'gpl2';
auto_license(holder => 'David Coppit');
no_index 'directory' => 'private-lib';

enable_verbose_cpan_testing();

use_standard_tests(without => 'pod_coverage');

WriteAll();
