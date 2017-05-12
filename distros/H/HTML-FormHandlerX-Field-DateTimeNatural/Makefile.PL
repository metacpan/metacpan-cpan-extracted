
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a datetime field with natural language parsing.",
  "AUTHOR" => "Roman F. <romanf\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-FormHandlerX-Field-DateTimeNatural",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTML::FormHandlerX::Field::DateTimeNatural",
  "PREREQ_PM" => {
    "DateTime::Format::Natural" => 0,
    "HTML::FormHandler::Field::Text" => 0,
    "HTML::FormHandler::Moose" => 0,
    "MooseX::Types::DateTime" => 0,
    "namespace::autoclean" => 0,
    "version" => 0
  },
  "TEST_REQUIRES" => {
    "FindBin" => 0,
    "HTML::FormHandler" => 0,
    "Test::More" => 0,
    "lib" => 0
  },
  "VERSION" => "v0.6",
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



