
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "simple interface to Google+",
  "AUTHOR" => "Zak B. Elep <zakame\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Net::Ping" => 0,
    "Test::More" => 0,
    "Test::Most" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Google-Plus",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Google::Plus",
  "PREREQ_PM" => {
    "Carp" => 0,
    "IO::Socket::SSL" => "1.37",
    "Mojo::Base" => 0,
    "Mojo::URL" => 0,
    "Mojo::UserAgent" => 0
  },
  "VERSION" => "0.004",
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



