#!/usr/bin/perl
use strict;
use warnings;
use 5.014;
use Test::More;
use Test::DZil;
use Test::Version qw( version_ok );
use Path::Tiny qw( path );

package Dist::Zilla::Plugin::MyVersionProvider {

  use Moose;
  with 'Dist::Zilla::Role::VersionProvider';

  sub provide_version
  {
    '1.00';
  }

}

my $tzil = Builder->from_config({ dist_root => 'corpus/version_provider' });

$tzil->build;

version_ok( path($tzil->tempdir)->child('build/lib/DZT0.pm'));

done_testing;

