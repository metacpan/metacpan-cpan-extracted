
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Code coverage metrics for your distribution",
  "AUTHOR" => "Marcel Gr\303\274nauer <marcel\@cpan.org>, Mike Doherty <doherty\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Dist-Zilla-App-Command-cover",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::App::Command::cover",
  "PREREQ_PM" => {
    "Devel::Cover" => 0,
    "Dist::Zilla::App" => 0,
    "File::Temp" => 0,
    "File::chdir" => 0,
    "Path::Class" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.101001",
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



