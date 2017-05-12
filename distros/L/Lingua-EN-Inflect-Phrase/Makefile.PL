
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Inflect short English Phrases",
  "AUTHOR" => "Rafael Kitover <rkitover\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0,
    "Test::NoWarnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Lingua-EN-Inflect-Phrase",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Lingua::EN::Inflect::Phrase",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "Lingua::EN::FindNumber" => 0,
    "Lingua::EN::Inflect" => 0,
    "Lingua::EN::Inflect::Number" => 0,
    "Lingua::EN::Number::IsOrdinal" => 0,
    "Lingua::EN::Tagger" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.18",
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



