
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
  "dist_abstract" => "For automated file archiving with Git",
  "dist_author" => [
    "Dominic Humphries <dominic\@oneandoneis2.com>"
  ],
  "dist_name" => "Git-Archive",
  "dist_version" => "0.10",
  "license" => "perl",
  "module_name" => "Git::Archive",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Git::Repository" => 0,
    "IPC::Cmd" => 0,
    "perl" => "v5.10.0",
    "strict" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Data::Dumper" => 0,
    "File::Path" => 0,
    "Test::More" => "0.88"
  }
);


my %fallback_build_requires = (
  "Data::Dumper" => 0,
  "File::Path" => 0,
  "Module::Build" => "0.3601",
  "Test::More" => "0.88"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
