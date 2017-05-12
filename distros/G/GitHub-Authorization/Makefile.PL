
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Generate a GitHub OAuth2 non-web authorization token",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "GitHub-Authorization",
  "EXE_FILES" => [],
  "LICENSE" => "lgpl",
  "NAME" => "GitHub::Authorization",
  "PREREQ_PM" => {
    "Carp" => 0,
    "HTTP::Tiny" => 0,
    "IO::Socket::SSL" => "1.56",
    "MIME::Base64" => 0,
    "Mozilla::CA" => 0,
    "Params::Validate" => 0,
    "Sub::Exporter::Progressive" => 0,
    "autobox::JSON" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.001",
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



