#!/usr/bin/perl -w
use strict;
use Module::Build::WithXSpp;

my $build = Module::Build::WithXSpp->new(
  module_name     => 'Lingua::Identify::CLD2',
  license         => 'perl',
  requires        => {
  },
  # Provides useful extra C typemaps for opaque objects:
  extra_typemap_modules => {
    'ExtUtils::Typemaps::ObjectMap'  => '0.01',
    'ExtUtils::Typemap::STL::String' => '0.04',
    'ExtUtils::Typemap::Basic'       => '0.04',
  },
  early_includes => [qw()],
  extra_compiler_flags => [ "-Isrc/cld2/internal", "-Isrc/cld2/public", "-Icld2/internal", "-Icld2/public" ],
  #extra_linker_flags   => [ (defined($additional_link_dir) ? "-L$additional_link_dir" : ()), "-lcld2_full" ],
);

$build->create_build_script;
