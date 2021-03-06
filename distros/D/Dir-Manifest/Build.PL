
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.012.
use strict;
use warnings;

use Module::Build 0.28;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.28"
  },
  "configure_requires" => {
    "Module::Build" => "0.28"
  },
  "dist_abstract" => "treat a directory and a manifest file as a hash/dictionary of keys to texts or blobs",
  "dist_author" => [
    "Shlomi Fish <shlomif\@cpan.org>"
  ],
  "dist_name" => "Dir-Manifest",
  "dist_version" => "0.6.1",
  "license" => "mit",
  "module_name" => "Dir::Manifest",
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter" => 0,
    "Moo" => 0,
    "Path::Tiny" => 0,
    "Socket" => 0,
    "parent" => 0,
    "perl" => "5.014",
    "strict" => 0,
    "warnings" => 0
  },
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.88"
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.28",
  "Test::More" => "0.88"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);


$build->create_build_script;
