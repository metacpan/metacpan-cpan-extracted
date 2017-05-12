
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
  "dist_abstract" => "test module",
  "dist_author" => [
    "Yanick Champoux <yanick\@babyl.dyndns.org>"
  ],
  "dist_name" => "DZT-Sample",
  "dist_version" => "1.0",
  "license" => "perl",
  "module_name" => "DZT::Sample",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {},
  "script_files" => [],
  "share_dir" => {
    "dist" => "share"
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
