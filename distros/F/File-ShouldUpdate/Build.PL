
# This file was automatically generated by Dist::Zilla::Plugin::ModuleBuild v6.024.
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
  "dist_abstract" => "should files be rebuilt?",
  "dist_author" => [
    "Shlomi Fish <shlomif\@cpan.org>"
  ],
  "dist_name" => "File-ShouldUpdate",
  "dist_version" => "0.2.1",
  "license" => "mit",
  "module_name" => "File::ShouldUpdate",
  "recursive_test_files" => 1,
  "requires" => {
    "Exporter" => 0,
    "Time::HiRes" => 0,
    "parent" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "test_requires" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Path::Tiny" => 0,
    "Test::More" => "0.88",
    "perl" => "5.006"
  }
);


my %fallback_build_requires = (
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Module::Build" => "0.28",
  "Path::Tiny" => 0,
  "Test::More" => "0.88",
  "perl" => "5.006"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);


$build->create_build_script;
