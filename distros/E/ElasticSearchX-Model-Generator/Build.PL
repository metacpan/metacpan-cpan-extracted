
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4202"
  },
  "configure_requires" => {
    "Module::Build" => "0.4202"
  },
  "dist_abstract" => "Create a suite of ESX::Model classes from an existing mapping.",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "ElasticSearchX-Model-Generator",
  "dist_version" => "0.1.8",
  "license" => "perl",
  "module_name" => "ElasticSearchX::Model::Generator",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Dump" => 0,
    "HTTP::Tiny" => 0,
    "JSON" => 0,
    "Module::Runtime" => 0,
    "Moo" => 0,
    "MooseX::Has::Sugar" => 0,
    "Path::Tiny" => 0,
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "Sub::Quote" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "ElasticSearchX::Model::Document" => "v0.1.5",
    "FindBin" => 0,
    "Moose" => 0,
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "ElasticSearchX::Model::Document" => "v0.1.5",
  "FindBin" => 0,
  "Module::Build" => "0.4202",
  "Moose" => 0,
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
