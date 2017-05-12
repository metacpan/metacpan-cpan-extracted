
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Schema class scaffold generator for DBIx::Class",
  "AUTHOR" => "Graham Barr",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Mesoderm",
  "EXE_FILES" => [
    "bin/mesoderm"
  ],
  "LICENSE" => "perl",
  "NAME" => "Mesoderm",
  "PREREQ_PM" => {
    "DBI" => 0,
    "Data::Dumper" => 0,
    "File::Temp" => 0,
    "Lingua::EN::Inflect::Number" => 0,
    "Moose" => "0.98",
    "MooseX::Getopt" => 0,
    "MooseX::Types::Path::Class" => 0,
    "Path::Class" => 0,
    "SQL::Translator" => "0.11008"
  },
  "VERSION" => "0.140780",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



