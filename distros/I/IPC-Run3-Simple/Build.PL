
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::CheckDeps" => 0,
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "Test::NoWarnings" => 0,
    "Test::Requires" => 0,
    "Test::UseAllModules" => 0,
    "perl" => "5.004"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Simple utility module to make the easy to use IPC::Run3 even more easy to use.",
  "dist_author" => [
    "Alan Young <harleypig\@gmail.com>"
  ],
  "dist_name" => "IPC-Run3-Simple",
  "dist_version" => "0.011",
  "license" => "perl",
  "module_name" => "IPC::Run3::Simple",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Capture::Tiny" => 0,
    "Carp" => 0,
    "Exporter" => 0,
    "IPC::Run3" => 0,
    "Time::HiRes" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
