
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Fvwm module for tiling windows",
  "dist_author" => [
    "Kathryn Andersen"
  ],
  "dist_name" => "FvwmPiazza",
  "dist_version" => "0.3001",
  "license" => "perl",
  "module_name" => "FvwmPiazza",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Class::Base" => 0,
    "FVWM::Module" => 0,
    "General::Parse" => 0,
    "Getopt::Long" => 0,
    "Module::Pluggable" => 0,
    "YAML::Syck" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "scripts/FvwmPiazza"
  ],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
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
