
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "#clip output to clipboard",
  "AUTHOR" => "Steve Nolte <mcsnolte\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Devel-REPL-Plugin-Clipboard",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Devel::REPL::Plugin::Clipboard",
  "PREREQ_PM" => {
    "Clipboard" => 0,
    "Devel::REPL::Plugin" => 0,
    "Term::ANSIColor" => "2.01",
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.004",
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



