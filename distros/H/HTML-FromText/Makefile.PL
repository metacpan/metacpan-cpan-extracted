
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "converts plain text to HTML",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>, Casey West <casey\@geeknest.com>, Gareth Rees <garethr\@cre.canon.co.uk>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-FromText",
  "EXE_FILES" => [
    "bin/text2html"
  ],
  "LICENSE" => "perl",
  "NAME" => "HTML::FromText",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Email::Find::addrspec" => "0.09",
    "Exporter" => "5.58",
    "HTML::Entities" => "1.26",
    "Scalar::Util" => "1.12",
    "Text::Tabs" => "98.1128",
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Find" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.96"
  },
  "VERSION" => "2.07",
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



