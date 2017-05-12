
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "File::ShareDir returning Path::Class objects",
  "dist_author" => [
    "Jerome Quelin"
  ],
  "dist_name" => "File-ShareDir-PathClass",
  "dist_version" => "1.112440",
  "license" => "perl",
  "module_name" => "File::ShareDir::PathClass",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "File::ShareDir" => 0,
    "Path::Class" => 0,
    "Sub::Exporter" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
