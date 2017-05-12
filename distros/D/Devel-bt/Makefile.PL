
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Automatic gdb backtraces on errors",
  "AUTHOR" => "Florian Ragwitz <rafl\@debian.org>",
  "BUILD_REQUIRES" => {
    "Capture::Tiny" => 0,
    "Config" => 0,
    "POSIX" => 0,
    "Test::More" => "0.89"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Devel-bt",
  "EXE_FILES" => [],
  "LICENSE" => "lgpl",
  "NAME" => "Devel::bt",
  "PREREQ_PM" => {
    "Carp" => 0,
    "File::Which" => 0,
    "XSLoader" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.06",
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



