
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
  "dist_abstract" => "a set of historic maps for Games::Risk",
  "dist_author" => [
    "Jerome Quelin"
  ],
  "dist_name" => "Games-Risk-ExtraMaps-History",
  "dist_version" => "3.112691",
  "license" => "gpl",
  "module_name" => "Games::Risk::ExtraMaps::History",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Games::Risk::ExtraMaps" => 0,
    "Games::Risk::Map" => 0,
    "Locale::Messages" => 0,
    "Locale::TextDomain" => 0,
    "Moose" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "share_dir" => {
    "dist" => "share"
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
