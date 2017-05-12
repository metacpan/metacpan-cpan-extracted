
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Pull author contribution counts for github repos",
  "AUTHOR" => "justin.d.hunter\@gmail.com",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Github-Score",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Github::Score",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "HTTP::Request" => 0,
    "JSON" => 0,
    "LWP" => 0,
    "Moose" => 0,
    "URI" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.2.0",
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



