
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "Module::Build" => "0.3601",
    "Test::File::ShareDir" => "v0.3.0",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Deal transparently with shared files distributed as tarballs",
  "dist_author" => [
    "Yanick Champoux <yanick\@babyl.dyndns.org>"
  ],
  "dist_name" => "File-ShareDir-Tarball",
  "dist_version" => "0.2.2",
  "license" => "perl",
  "module_name" => "File::ShareDir::Tarball",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Archive::Tar" => 0,
    "Carp" => 0,
    "Exporter" => 0,
    "File::ShareDir" => 0,
    "File::Temp" => 0,
    "File::chdir" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
