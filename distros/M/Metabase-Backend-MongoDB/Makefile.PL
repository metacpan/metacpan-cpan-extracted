
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Metabase backend implemented using MongoDB",
  "AUTHOR" => "David Golden <dagolden\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Metabase::Test::Archive" => 0,
    "Metabase::Test::Index" => 0,
    "Test::Deep" => 0,
    "Test::More" => "0.92",
    "Test::Routine" => 0,
    "Test::Routine::Util" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Metabase-Backend-MongoDB",
  "EXE_FILES" => [],
  "LICENSE" => "apache",
  "NAME" => "Metabase::Backend::MongoDB",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Compress::Zlib" => 2,
    "Data::Stream::Bulk::Callback" => 0,
    "JSON" => 2,
    "Metabase::Archive" => "0.017",
    "Metabase::Fact" => 0,
    "Metabase::Index" => "0.017",
    "MongoDB" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Regexp::SQL::LIKE" => "0.001",
    "Try::Tiny" => 0,
    "boolean" => 0,
    "namespace::autoclean" => 0,
    "re" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.000",
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



