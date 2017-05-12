
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
  "dist_abstract" => "A reader/writer for the C<metadata/perl/distmap.json> file.",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Gentoo-Perl-Distmap",
  "dist_version" => "0.2.0",
  "license" => "perl",
  "module_name" => "Gentoo::Perl::Distmap",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Dump" => 0,
    "Digest::SHA" => 0,
    "JSON" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Path::Tiny" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Test::More" => "0.98",
    "perl" => "v5.10.0"
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
