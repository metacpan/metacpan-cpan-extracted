
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4007"
  },
  "configure_requires" => {
    "Module::Build" => "0.4007"
  },
  "dist_abstract" => "Convert a canonicalized (R|P|)DEPEND into an Abstract Syntax Tree",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Gentoo-Dependency-AST",
  "dist_version" => "0.001001",
  "license" => "perl",
  "module_name" => "Gentoo::Dependency::AST",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Class::Tiny" => 0,
    "parent" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Data::Dump" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.99"
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
