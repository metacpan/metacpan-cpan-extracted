#! /usr/bin/perl
#---------------------------------------------------------------------
# Build.PL
# Copyright 2012 Christopher J. Madsen
#
# Build.PL for MSDOS-Attrib
#---------------------------------------------------------------------

use strict;
#use warnings;         # Wasn't core until 5.6.0

unless ($^O eq "MSWin32" || $^O eq "cygwin" || $^O eq 'os2') {
  die "OS unsupported\n";
}

use Module::Build;

my $builder = Module::Build->new(
  module_name        => 'MSDOS::Attrib',
  license            => 'perl',
  dist_author        => 'Christopher J. Madsen <perl@cjmweb.net>',
  dist_version_from  => 'lib/MSDOS/Attrib.pm',
  'build_requires' => {
    'ExtUtils::CBuilder' => '0.15',
    'ExtUtils::ParseXS' => '0',
    'Module::Build' => '0.2808',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.2808'
  },
  'requires' => {
    'Carp' => '0',
    'Exporter' => '0',
    'XSLoader' => '0',
    'perl' => '5.005'
  },
);

$builder->create_build_script();
