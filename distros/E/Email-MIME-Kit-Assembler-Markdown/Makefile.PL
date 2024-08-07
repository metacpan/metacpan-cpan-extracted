# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.029.
use strict;
use warnings;

use 5.012;

use ExtUtils::MakeMaker 6.78;

my %WriteMakefileArgs = (
  "ABSTRACT" => "build multipart/alternative messages from Markdown alone",
  "AUTHOR" => "Ricardo Signes <cpan\@semiotic.systems>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.78"
  },
  "DISTNAME" => "Email-MIME-Kit-Assembler-Markdown",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.012",
  "NAME" => "Email::MIME::Kit::Assembler::Markdown",
  "PREREQ_PM" => {
    "Email::MIME" => "1.900",
    "Email::MIME::Kit" => "3.000001",
    "Email::MIME::Kit::Role::Assembler" => 0,
    "HTML::Entities" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Text::Markdown" => 0
  },
  "TEST_REQUIRES" => {
    "Email::MIME::Kit" => "3.000001",
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => "0.96",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.100009",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Email::MIME" => "1.900",
  "Email::MIME::Kit" => "3.000001",
  "Email::MIME::Kit::Role::Assembler" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "HTML::Entities" => 0,
  "Moose" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "Test::More" => "0.96",
  "Text::Markdown" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
