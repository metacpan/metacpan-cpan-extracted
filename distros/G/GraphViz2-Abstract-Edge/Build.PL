
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4203"
  },
  "configure_requires" => {
    "Module::Build" => "0.4203"
  },
  "dist_abstract" => "Deal with edges independent of a Graph",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "GraphViz2-Abstract-Edge",
  "dist_version" => "0.002000",
  "license" => "perl",
  "module_name" => "GraphViz2::Abstract::Edge",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Class::Tiny" => 0,
    "GraphViz2::Abstract::Util::Constants" => 0,
    "Scalar::Util" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "GraphViz2" => 0,
    "Path::Tiny" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "1.001002",
    "parent" => 0
  }
);


my %fallback_build_requires = (
  "GraphViz2" => 0,
  "Module::Build" => "0.4203",
  "Path::Tiny" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "1.001002",
  "parent" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
