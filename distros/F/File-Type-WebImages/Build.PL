#!/usr/bin/perl
use Module::Build;

use strict;

Module::Build->new(
  module_name => 'File::Type::WebImages',
  license     => 'perl',
  requires => {
    'Test::More'  => 0.01,
    'IO::File'    => 0.01,
  },
  create_makefile_pl => 'traditional',
)->create_build_script;
