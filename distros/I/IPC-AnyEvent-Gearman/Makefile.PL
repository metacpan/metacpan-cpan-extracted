
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "IPC through gearmand.",
  "AUTHOR" => "KHS, HyeonSeung Kim <sng2nara\@hanmail.net>",
  "BUILD_REQUIRES" => {
    "EV" => 0,
    "IO::Socket::INET" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "IPC-AnyEvent-Gearman",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "IPC::AnyEvent::Gearman",
  "PREREQ_PM" => {
    "Any::Moose" => 0,
    "AnyEvent" => 0,
    "AnyEvent::Gearman" => 0,
    "AnyEvent::Gearman::Worker::Connection" => 0,
    "AnyEvent::Handle" => 0,
    "AnyEvent::Socket" => 0,
    "Data::Dumper" => 0,
    "Devel::GlobalDestruction" => 0,
    "Gearman::Server" => 0,
    "Log::Log4perl" => 0,
    "Scalar::Util" => 0,
    "UUID::Random" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.8",
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



