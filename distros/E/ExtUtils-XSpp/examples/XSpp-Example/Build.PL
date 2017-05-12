#!/usr/bin/perl -w
use strict;
use Module::Build::WithXSpp;

my $build = Module::Build::WithXSpp->new(
  module_name     => 'XSpp::Example',
  license         => 'perl',
  requires        => {},
  # Provides useful extra C typemaps for opaque objects:
  extra_typemap_modules => {
    'ExtUtils::Typemaps::ObjectMap' => '0.01',
  },
);

$build->create_build_script;
