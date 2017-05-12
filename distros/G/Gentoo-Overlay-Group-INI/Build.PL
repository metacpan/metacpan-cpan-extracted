
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "File::Tempdir" => 0,
    "FindBin" => 0,
    "Module::Build" => "0.4003",
    "Test::Fatal" => 0,
    "Test::More" => "0.98",
    "autodie" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.4003"
  },
  "dist_abstract" => "Load a list of overlays defined in a configuration file.",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Gentoo-Overlay-Group-INI",
  "dist_version" => "0.2.2",
  "license" => "perl",
  "module_name" => "Gentoo::Overlay::Group::INI",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Config::MVP::Assembler" => 0,
    "Config::MVP::Reader" => 0,
    "Config::MVP::Reader::INI" => 0,
    "Config::MVP::Section" => 0,
    "File::HomeDir" => 0,
    "Gentoo::Overlay::Exceptions" => 0,
    "Gentoo::Overlay::Group" => 0,
    "Moose" => 0,
    "Path::Tiny" => 0,
    "String::RewritePrefix" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
