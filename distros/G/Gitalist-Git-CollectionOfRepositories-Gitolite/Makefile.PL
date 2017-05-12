
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Adds support for gitolite to gitalist",
  "AUTHOR" => "Gavin Mogan <halkeye\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Gitalist-Git-CollectionOfRepositories-Gitolite",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Gitalist::Git::CollectionOfRepositories::Gitolite",
  "PREREQ_PM" => {
    "File::Basename" => 0,
    "Gitalist" => "0.003009",
    "MooseX::Declare" => "0.32"
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => ""
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



