use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
  NAME             => 'Devel::Cover::Report::SonarGeneric',
  VERSION_FROM     => 'lib/Devel/Cover/Report/SonarGeneric.pm',
  ABSTRACT         => 'SonarQube generic backend for Devel::Cover',
  AUTHOR           => 'Thomas Kratz <tomk@cpan.org>',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => 5.010001,
  META_MERGE       => {
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/tomk3003/devel-cover-report-sonargeneric',
      bugtracker  => 'https://github.com/tomk3003/devel-cover-report-sonargeneric/issues'
    },
    no_index => {directory => ['t']}
  },
  PREREQ_PM => {
    "Devel::Cover" => 0,
    "Path::Tiny"   => 0,
  },
  TEST_REQUIRES => {
    "JSON::MaybeXS" => 0,
  },
  test => {TESTS => 't/*.t'}
);
