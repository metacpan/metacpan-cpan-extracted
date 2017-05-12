
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "IO::Select" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Log messages to a remote UDP socket",
  "dist_author" => [
    "Rob Hoelz <rob\@hoelz.ro>"
  ],
  "dist_name" => "Log-Dispatch-UDP",
  "dist_version" => "0.01",
  "license" => "perl",
  "module_name" => "Log::Dispatch::UDP",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "IO::Socket::INET" => 0,
    "Log::Dispatch" => 0,
    "Readonly" => 0,
    "namespace::clean" => 0,
    "parent" => 0,
    "perl" => "5.8.8"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
