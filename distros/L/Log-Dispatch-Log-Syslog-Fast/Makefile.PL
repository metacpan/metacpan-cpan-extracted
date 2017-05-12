
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Log::Dispatch wrapper around Log::Syslog::Fast",
  "AUTHOR" => "Adam Thomason <athomason\@cpan.org>",
  "BUILD_REQUIRES" => {
    "IO::Select" => 0,
    "IO::Socket::INET" => 0,
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Log-Dispatch-Log-Syslog-Fast",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Log::Dispatch::Log::Syslog::Fast",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Log::Dispatch" => 0,
    "Log::Syslog::Constants" => "1.02",
    "Log::Syslog::Fast" => "0.58",
    "Params::Validate" => 0,
    "Sys::Hostname" => 0,
    "parent" => 0
  },
  "VERSION" => "1.02",
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



