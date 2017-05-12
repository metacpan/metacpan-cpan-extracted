
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Deliver a piece of email - simply",
  "AUTHOR" => "Simon Cozens, Casey West <casey\@geeknest.com>, Ricardo Signes <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Email-LocalDelivery",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Email::LocalDelivery",
  "PREREQ_PM" => {
    "Carp" => "0",
    "Email::FolderType" => "0.7",
    "Email::Simple" => "1.998",
    "Fcntl" => "0",
    "File::Basename" => "0",
    "File::Path" => "0",
    "File::Path::Expand" => "1.01",
    "Symbol" => "0",
    "Sys::Hostname" => "0",
    "strict" => "0",
    "warnings" => "0"
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => "0",
    "Test::More" => "0.96",
    "blib" => "0"
  },
  "VERSION" => "1.200",
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



