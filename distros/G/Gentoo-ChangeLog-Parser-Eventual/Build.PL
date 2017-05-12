
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
  "dist_abstract" => "Rudimentary Event-Based ChangeLog format parser, inspired by Pod::Eventual.",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Gentoo-ChangeLog-Parser-Eventual",
  "dist_version" => "0.1.2",
  "license" => "perl",
  "module_name" => "Gentoo::ChangeLog::Parser::Eventual",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Moose" => 0,
    "namespace::clean" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Path::Class" => 0,
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
