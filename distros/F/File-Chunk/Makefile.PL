
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Read/Write file handles that are stored as seperate, size-limited files on disk",
  "AUTHOR" => "Dylan William Hardison <dylan\@hardison.net>",
  "BUILD_REQUIRES" => {
    "IO::String" => 0,
    "Test::More" => 0,
    "Test::TempDir" => 0,
    "Text::CSV_XS" => 0,
    "ok" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "File-Chunk",
  "EXE_FILES" => [
    "bin/file-chunk-write"
  ],
  "LICENSE" => "perl",
  "NAME" => "File::Chunk",
  "PREREQ_PM" => {
    "Bread::Board::Declare" => 0,
    "Carp" => 0,
    "English" => 0,
    "IO::Handle::Util" => 0,
    "List::MoreUtils" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Getopt::GLD" => 0,
    "MooseX::Params::Validate" => 0,
    "MooseX::SetOnce" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Path::Class" => 0,
    "Path::Class::Rule" => 0,
    "YAML::XS" => 0,
    "namespace::autoclean" => 0,
    "namespace::clean" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0035",
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



