#!/usr/bin/env perl

use warnings FATAL => 'all';
use strict;
use Module::Build;

my $build = Module::Build->new(
  module_name => 'Getopt::Complete',
  license => 'perl',
  requires => {
    'perl'              => 'v5.8.7',
    'Getopt::Long'      => '',
    'Scalar::Util'      => '',
    'IPC::Open2'        => '',
    'Carp'              => '',
  },
  build_requires => {
    'Test::More'        => '0.86',
    'App::Prove'        => '',
  },
  cpan_client => 'cpanm',
  #script_files => [ 'bin/ur' ],
  #test_files => [qw|t/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t|],
);
$build->create_build_script;


