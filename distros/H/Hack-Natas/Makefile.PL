
use strict;
use warnings;

use 5.016000;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "walkthrough";


my %WriteMakefileArgs = (
  "ABSTRACT" => "solve some of the Natas server-side security war games",
  "AUTHOR" => "Mike Doherty <doherty\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "File::ShareDir::Install" => "0.03",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Hack-Natas",
  "EXE_FILES" => [
    "bin/natas16",
    "bin/natas15"
  ],
  "LICENSE" => "perl",
  "NAME" => "Hack::Natas",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "Getopt::Long" => 0,
    "HTTP::Tiny" => "0.034",
    "Moo" => "1.003000",
    "Moo::Role" => 0,
    "Term::ReadPassword" => 0,
    "Type::Utils" => 0,
    "Types::Standard" => 0,
    "URI" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "Test::More" => "0.88",
    "Test::Script" => "1.05",
    "blib" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


