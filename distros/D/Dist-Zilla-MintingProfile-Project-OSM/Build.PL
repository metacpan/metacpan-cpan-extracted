
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A minting profile for Modules written for Project OSM",
  "dist_author" => [
    "DBR <dbr\@cpan.org>, AHERNIT <tech\@tool.de>"
  ],
  "dist_name" => "Dist-Zilla-MintingProfile-Project-OSM",
  "dist_version" => "0.2.0",
  "license" => "perl",
  "module_name" => "Dist::Zilla::MintingProfile::Project::OSM",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dist::Zilla::Role::MintingProfile::ShareDir" => 0,
    "Moose" => 0,
    "namespace::autoclean" => 0
  },
  "script_files" => [],
  "share_dir" => {
    "module" => {
      "Dist::Zilla::MintingProfile::Project::OSM" => "profiles"
    }
  },
  "test_requires" => {
    "Carp" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec::Functions" => 0,
    "List::Util" => 0,
    "Scalar::Util" => 0,
    "Test::CheckDeps" => "0.002",
    "Test::More" => "0.94",
    "Test::UseAllModules" => 0,
    "perl" => "5.004",
    "strict" => 0,
    "warnings" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
