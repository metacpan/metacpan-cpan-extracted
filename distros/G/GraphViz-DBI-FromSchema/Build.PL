#! /usr/bin/perl


use warnings;
use strict;

use Module::Build;


Module::Build->new
(
  module_name => 'GraphViz::DBI::FromSchema',
  license => 'perl',
  dist_author => 'Smylers <smylers@cpan.org>',
  dist_version_from => 'lib/GraphViz/DBI/FromSchema.pm',
  requires =>
  {
    'GraphViz::DBI' => 0,
    'Getopt::Long' => 0,
    'File::Temp' => 0,
  },
  build_requires =>
  {
    'Test::More' => 0,
  },
  add_to_cleanup => ['GraphViz-DBI-FromSchema-*'],
  create_makefile_pl => 'traditional',
)->create_build_script;
