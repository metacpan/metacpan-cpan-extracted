
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Helpers for keeping a set of related .po files in sync",
  "AUTHOR" => "Jesse Luehrs <doy at tozt dot net>",
  "BUILD_REQUIRES" => {
    "File::Copy" => 0,
    "File::Find" => 0,
    "File::Temp" => "0.19",
    "Path::Class" => 0,
    "Test::More" => "0.88",
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Locale-POFileManager",
  "EXE_FILES" => [
    "bin/po_add_stubs",
    "bin/po_find_missing"
  ],
  "LICENSE" => "perl",
  "NAME" => "Locale::POFileManager",
  "PREREQ_PM" => {
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Locale::Maketext::Lexicon" => 0,
    "Locale::Maketext::Lexicon::Gettext" => 0,
    "Moose" => "0.90",
    "MooseX::Types::Path::Class" => 0,
    "Scalar::Util" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.05",
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



