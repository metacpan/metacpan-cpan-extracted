
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Cwd" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Module::Build" => "0.4001",
    "Test::More" => "0.98"
  },
  "configure_requires" => {
    "Module::Build" => "0.4001"
  },
  "dist_abstract" => "Inflate any archive to a temporary directory and work in it.",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "File-Tempdir-ForPackage-FromArchive",
  "dist_version" => "0.1.0",
  "license" => "perl",
  "module_name" => "File::Tempdir::ForPackage::FromArchive",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Archive::Any" => 0,
    "File::Tempdir::ForPackage" => 0,
    "Moo" => 0,
    "Sub::Quote" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
