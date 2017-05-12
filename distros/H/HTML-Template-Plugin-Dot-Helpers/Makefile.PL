
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Add useful objects to your templates",
  "AUTHOR" => "Rhesa Rozendaal <rhesa\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-Template-Plugin-Dot-Helpers",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTML::Template::Plugin::Dot::Helpers",
  "PREREQ_PM" => {
    "HTML::Template::Pluggable" => "0.12",
    "HTML::Template::Plugin::Dot" => "0.96",
    "Number::Format" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.06",
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



