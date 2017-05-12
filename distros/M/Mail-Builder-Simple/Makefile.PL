
use strict;
use warnings;

use 5.008_008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Send UTF-8 HTML and text email with attachments and inline images, eventually using templates\r",
  "AUTHOR" => "Octavian Rasnita <orasnita\@gmail.com>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Test::More" => 0,
    "Test::Pod" => 0,
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Mail-Builder-Simple",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Mail::Builder::Simple",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Config::Any" => 0,
    "Cwd" => 0,
    "Email::Sender::Simple" => 0,
    "Email::Valid" => 0,
    "Encode" => 0,
    "Exception::Died" => 0,
    "HTML::Template" => 0,
    "Mail::Builder" => 0,
    "Module::Load" => 0,
    "Template" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.16",
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



