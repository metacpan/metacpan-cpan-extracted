
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Run a process with control over any FDs it may use.",
  "AUTHOR" => "Stephen R. Scaffidi <sscaffidi\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Capture::Tiny" => 0,
    "File::Find" => 0,
    "File::Slurp" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "IPC-OpenAny",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "IPC::OpenAny",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "English" => 0,
    "Exporter" => 0,
    "Params::Util" => 0,
    "autodie" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.005",
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



