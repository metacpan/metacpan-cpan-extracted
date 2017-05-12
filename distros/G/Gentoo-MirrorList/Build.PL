
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4004"
  },
  "configure_requires" => {
    "Module::Build" => "0.4004"
  },
  "dist_abstract" => "A programmatic way to access Gentoo.org Mirror Metadata",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Gentoo-MirrorList",
  "dist_version" => "1.0.2",
  "license" => "perl",
  "module_name" => "Gentoo::MirrorList",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "App::Cache" => 0,
    "Carp" => 0,
    "Moose" => 0,
    "XML::Simple" => 0,
    "namespace::autoclean" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Test::More" => "0.98"
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
