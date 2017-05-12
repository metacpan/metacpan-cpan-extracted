
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
  "dist_abstract" => "cooperative pandemic board game",
  "dist_author" => [
    "Jerome Quelin"
  ],
  "dist_name" => "Games-Pandemic",
  "dist_version" => "1.120510",
  "license" => "gpl",
  "module_name" => "Games::Pandemic",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Convert::Color" => 0,
    "Devel::CheckOS" => 0,
    "Encode" => 0,
    "Exporter" => 0,
    "Exporter::Lite" => 0,
    "File::HomeDir" => 0,
    "File::ShareDir::PathClass" => 0,
    "File::Spec::Functions" => 0,
    "FindBin" => 0,
    "Geo::Mercator" => 0,
    "Image::Size" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Locale::TextDomain" => 0,
    "Math::Gradient" => 0,
    "Moose" => "0.92",
    "Moose::Role" => 0,
    "MooseX::Has::Sugar" => 0,
    "MooseX::POE" => 0,
    "MooseX::SemiAffordanceAccessor" => 0,
    "MooseX::Singleton" => 0,
    "MooseX::Traits" => 0,
    "MooseX::Types::Moose" => 0,
    "POE" => 0,
    "POE::Kernel" => 0,
    "POE::Loop::Tk" => 0,
    "Readonly" => 0,
    "Tk" => 0,
    "Tk::Action" => 0,
    "Tk::Balloon" => 0,
    "Tk::Font" => 0,
    "Tk::JPEG" => 0,
    "Tk::PNG" => 0,
    "Tk::Pane" => 0,
    "Tk::Sugar" => 0,
    "Tk::Tiler" => 0,
    "Tk::ToolBar" => 0,
    "UNIVERSAL::require" => 0,
    "YAML::Tiny" => 0,
    "perl" => "5.010",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/pandemic"
  ],
  "share_dir" => {
    "dist" => "share"
  }
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
