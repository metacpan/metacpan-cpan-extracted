
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Incremental log reader with a transparent rotation handling",
  "AUTHOR" => "Andrei Mishchenko <druxa\@yandex-team.ru>, Vyacheslav Matjukhin <mmcleric\@yandex-team.ru>",
  "BUILD_REQUIRES" => {
    "Exporter" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::stat" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Test::NoWarnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Log-Unrotate",
  "EXE_FILES" => [
    "bin/unrotate"
  ],
  "LICENSE" => "perl",
  "NAME" => "Log::Unrotate",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Digest::MD5" => 0,
    "Fcntl" => 0,
    "File::Basename" => 0,
    "File::Temp" => "0.15",
    "Getopt::Long" => "2.33",
    "IO::Handle" => 0,
    "Pod::Usage" => 0,
    "base" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.32",
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



