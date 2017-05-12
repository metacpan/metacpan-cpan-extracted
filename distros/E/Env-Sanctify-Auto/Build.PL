#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id: Build.PL 8217 2009-07-25 22:35:54Z FREQUENCY@cpan.org $
#
# All rights to this helper script are hereby disclaimed and its contents
# released into the public domain by the author. Where this is not possible,
# you may use this file under the same terms as Perl itself.

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
  module_name           => 'Env::Sanctify::Auto',
  license               => 'perl',
  dist_author           => 'Jonathan Yu <frequency@cpan.org>',
  dist_version_from     => 'lib/Env/Sanctify/Auto.pm',
  dynamic_config        => 0,
  create_readme         => 0,
  recursive_test_files  => 1,
  sign                  => 1,
  create_packlist       => 1,

  # Maintain compatibility with ExtUtils::MakeMaker installations
  create_makefile_pl    => 'passthrough',

  requires => {
    'perl'              => 5.006,
    'Env::Sanctify'     => 0,

    # Pragmatic and special modules
    'Carp'              => 1.04,
    'version'           => 0.74,
    'warnings'          => 0,
    'strict'            => 0,
  },
  build_requires => {
    # User tests for good functionality
    'Test::NoWarnings'        => 0.084,
    'Test::More'              => 0,
  },
  recommends => {
  },
  conflicts => {
  },

  add_to_cleanup => [ 'Env-Sanctify-Auto-*' ],
  script_files => [],

  meta_merge => {
    resources => {
      # Custom resources (must begin with an uppercase letter)
      Ratings      => 'http://cpanratings.perl.org/d/Env-Sanctify-Auto',

      # Official keys (homepage, license, bugtracker)
      repository   => 'http://svn.ali.as/cpan/trunk/Env-Sanctify-Auto',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Env-Sanctify-Auto',
      license      => 'http://dev.perl.org/licenses/',
    },
  },
);

$builder->create_build_script();
