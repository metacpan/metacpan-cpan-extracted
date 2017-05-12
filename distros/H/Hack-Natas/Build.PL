
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "File::ShareDir::Install" => "0.03",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "solve some of the Natas server-side security war games",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "Hack-Natas",
  "dist_version" => "0.003",
  "license" => "perl",
  "module_name" => "Hack::Natas",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "Getopt::Long" => 0,
    "HTTP::Tiny" => "0.034",
    "Moo" => "1.003000",
    "Moo::Role" => 0,
    "Term::ReadPassword" => 0,
    "Type::Utils" => 0,
    "Types::Standard" => 0,
    "URI" => 0,
    "perl" => "v5.16.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/natas16",
    "bin/natas15"
  ],
  "share_dir" => {
    "dist" => "walkthrough"
  },
  "test_requires" => {
    "Capture::Tiny" => 0,
    "Test::More" => "0.88",
    "Test::Script" => "1.05",
    "blib" => 0
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
