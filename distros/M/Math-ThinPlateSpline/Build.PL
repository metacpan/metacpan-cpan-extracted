#!/usr/bin/perl -w
use strict;
use Module::Build::WithXSpp;

my $build = Module::Build::WithXSpp->new(
  module_name     => 'Math::ThinPlateSpline',
  license         => 'perl',
  # Provides extra C typemaps that are auto-merged
  extra_typemap_modules => {
    'ExtUtils::Typemaps::Default' => '0.05',
  },
);

$build->create_build_script;
