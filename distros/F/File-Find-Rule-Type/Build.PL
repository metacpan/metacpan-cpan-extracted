#!/usr/bin/perl
use Module::Build;

use strict;

Module::Build->new(
  module_name => 'File::Find::Rule::Type',
  license     => 'perl',
  requires => {
    'Test::More'  => 0.01,
    'File::Type'  => 0.05,
    'File::Find::Rule' => 0.07,
  },
  create_makefile_pl => 'traditional',
)->create_build_script;
