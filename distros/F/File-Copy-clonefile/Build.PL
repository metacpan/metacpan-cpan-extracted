
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.032.
use strict;
use warnings;

use Module::Build 0.28;
use lib qw{inc}; use MyBuilder;

my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.28"
  },
  "configure_requires" => {
    "IPC::Run3" => 0,
    "Module::Build" => "0.4205",
    "perl" => "v5.20.0"
  },
  "dist_abstract" => "call clonefile system call",
  "dist_author" => [
    "Shoichi Kaji <skaji\@cpan.org>"
  ],
  "dist_name" => "File-Copy-clonefile",
  "dist_version" => "v0.0.10",
  "license" => "perl",
  "module_name" => "File::Copy::clonefile",
  "recursive_test_files" => 1,
  "requires" => {
    "perl" => "v5.20.0"
  },
  "test_requires" => {
    "Test::LeakTrace" => 0
  }
);


my %fallback_build_requires = (
  "Module::Build" => "0.28",
  "Test::LeakTrace" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = MyBuilder->new(%module_build_args);


$build->create_build_script;
