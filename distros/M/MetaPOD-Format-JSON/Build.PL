
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
  "dist_abstract" => "Reference implementation of a C<JSON> based MetaPOD Format",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "MetaPOD-Format-JSON",
  "dist_version" => "0.3.0",
  "license" => "perl",
  "module_name" => "MetaPOD::Format::JSON",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "JSON" => 0,
    "MetaPOD::Exception::Decode::Data" => 0,
    "MetaPOD::Role::Format" => 0,
    "Moo" => "1.000008",
    "Moo::Role" => 0,
    "Try::Tiny" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "version" => "0.77",
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "FindBin" => 0,
    "MetaPOD::Assembler" => 0,
    "Path::Iterator::Rule" => 0,
    "Path::Tiny" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "FindBin" => 0,
  "MetaPOD::Assembler" => 0,
  "Module::Build" => "0.4202",
  "Path::Iterator::Rule" => 0,
  "Path::Tiny" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
