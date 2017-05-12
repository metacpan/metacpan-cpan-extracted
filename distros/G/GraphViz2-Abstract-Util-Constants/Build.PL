
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
  "dist_abstract" => "Constants used by C<GraphViz2::Abstract::*>",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "GraphViz2-Abstract-Util-Constants",
  "dist_version" => "0.001000",
  "license" => "perl",
  "module_name" => "GraphViz2::Abstract::Util::Constants",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter" => 0,
    "constant" => 0,
    "parent" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "Module::Build" => "0.4203",
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
