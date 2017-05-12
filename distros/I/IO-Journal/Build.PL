#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id: Build.PL 8236 2009-07-26 03:01:50Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name           => 'IO::Journal',
  license               => 'unrestricted',
  dist_author           => 'Jonathan Yu <frequency@cpan.org>',
  dist_version_from     => 'lib/IO/Journal.pm',
  dynamic_config        => 0,
  create_readme         => 0,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  # Maintain compatibility with ExtUtils::MakeMaker installations
  create_makefile_pl    => 'passthrough',

  # Location of our special C and XS source files
  c_source => 'src',
  xs_files => {
    'src/Journal.xs'      => 'lib/IO/Journal.xs',
    'src/Transaction.xs'  => 'lib/IO/Journal/Transaction.xs',
  },

  requires => {
    'perl'              => 5.006,

    # Pragmatic and special modules
    'Carp'              => 1.04,
    'version'           => 0,
    'warnings'          => 0,
    'strict'            => 0,
    'Fcntl'             => 0,

    # Use Alien::Libjio to ensure libjio is installed
    'Alien::Libjio'     => 0,

    # The tests are based on Test::More
    'Test::More'        => 0.62,
  },
  build_requires => {
    # User tests for good functionality
    'Test::NoWarnings'        => 0.084,

    # For the XS build process
    'ExtUtils::CBuilder'      => 0,
    'Alien::Libjio'           => 0,
  },
  recommends => {
  },
  conflicts => {
  },

  add_to_cleanup => [ 'IO-Journal-*' ],
  script_files => [],

  meta_merge => {
    resources => {
      # Custom resources (must begin with an uppercase letter)
      Ratings      => 'http://cpanratings.perl.org/d/IO-Journal',

      # Official keys (homepage, license, bugtracker)
      repository   => 'http://svn.ali.as/cpan/trunk/IO-Journal',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Journal',
      license      => 'http://edwardsamuels.com/copyright/beyond/articles/public.html',
    },
  },
);

$builder->create_build_script();
