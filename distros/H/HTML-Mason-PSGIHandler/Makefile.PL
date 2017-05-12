
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "PSGI handler for HTML::Mason",
  "AUTHOR" => "Tatsuhiko Miyagawa <miyagawa\@bulknews.net>, Ask Bj\303\270rn Hansen <ask\@develooper.com>, Ricardo Signes <rjbs\@cpan.org>, Ruslan Zakirov <ruz\@bestpractical.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTML-Mason-PSGIHandler",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTML::Mason::PSGIHandler",
  "PREREQ_PM" => {
    "CGI::PSGI" => 0,
    "HTML::Mason" => 0
  },
  "TEST_REQUIRES" => {
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Plack::Test" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.53",
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



