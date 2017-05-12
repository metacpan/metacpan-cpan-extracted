
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Utility to generate a random dir tree with random files.",
  "dist_author" => [
    "John Gravatt <john\@gravatt.org>"
  ],
  "dist_name" => "File-RandomGenerator",
  "dist_version" => "0.06",
  "license" => "perl",
  "module_name" => "File::RandomGenerator",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "File::Path" => 0,
    "File::Temp" => 0,
    "Getopt::Long" => 0,
    "Modern::Perl" => 0,
    "Moose" => 0,
    "Smart::Args" => 0,
    "constant" => 0,
    "namespace::autoclean" => 0,
    "vars" => 0
  },
  "script_files" => [
    "bin/gen_rand_files.pl"
  ],
  "test_requires" => {
    "Test::More" => 0
  }
);


my %fallback_build_requires = (
  "Module::Build" => "0.3601",
  "Test::More" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
