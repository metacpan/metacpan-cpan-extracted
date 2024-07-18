use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Easy installation of the GSL shared library",
  "AUTHOR" => "Joel A. Berger <joel.a.berger\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Alien::Build" => "2.21",
    "Alien::Build::MM" => "2.21",
    "ExtUtils::MakeMaker" => "6.52"
  },
  "CONFIGURE_REQUIRES" => {
    "Alien::Build" => "2.21",
    "Alien::Build::MM" => "2.21",
    "ExtUtils::MakeMaker" => "6.52",
    "Alien::Role::Dino" => 0
  },
  "DISTNAME" => "Math-GSL-Alien",
  "LICENSE" => "perl",
  "NAME" => "Math::GSL::Alien",
  "PREREQ_PM" => {
    "Alien::Base" => "2.21",
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.52",
    "Test2::V0" => 0,
    "Test::Alien" => 0,
    "Test::Alien::Diag" => 0,
  },
  "VERSION_FROM" => "lib/Math/GSL/Alien.pm",
  "test" => {
    "TESTS" => "t/*.t"
  },

  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {
        web  => 'https://github.com/hakonhagland/Math-GSL-Alien/issues',
      },
      homepage => 'https://metacpan.org/pod/Math::GSL::Alien',
      repository => {
        type => 'git',
        url  => 'https://github.com/hakonhagland/Math-GSL-Alien.git',
        web  => 'https://github.com/hakonhagland/Math-GSL-Alien',
      },
      x_IRC => "irc://irc.perl.org/#native",
    },
  },

);


my %FallbackPrereqs = (
  "Alien::Base" => "2.21",
  "Alien::Build" => "2.21",
  "Alien::Build::MM" => "2.21",
  "ExtUtils::MakeMaker" => "6.52",
  "File::Spec" => 0,
  "Sort::Versions" => 0,
  "Test::More" => 0
);


use Alien::Build::MM;
my $abmm = Alien::Build::MM->new;
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

WriteMakefile(%WriteMakefileArgs);


{ package
    MY;
  sub postamble {
    $abmm->mm_postamble(@_);
  }
  sub install {
    $abmm->can('mm_install')
      ? $abmm->mm_install(@_)
      : shift->SUPER::install(@_);
  }
}
