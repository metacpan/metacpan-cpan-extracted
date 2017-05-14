
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Generates exheres for perl modules",
  "dist_author" => [
    "William Orr <will\@worrbase.com>"
  ],
  "dist_name" => "Exherbo-Packager",
  "dist_version" => "1.133000",
  "license" => "mit",
  "module_name" => "Exherbo::Packager",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DateTime" => 0,
    "File::Copy" => 0,
    "Getopt::Long" => 0,
    "MetaCPAN::API" => 0,
    "Ouch" => 0,
    "Pod::Usage" => 0,
    "YAML::Any" => 0
  },
  "script_files" => [
    "bin/ex-packer"
  ],
  "test_requires" => {
    "Test::More" => 0,
    "Test::Perl::Critic" => 0
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
