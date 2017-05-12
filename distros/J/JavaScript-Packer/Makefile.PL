#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'JavaScript::Packer',
  ABSTRACT_FROM => 'lib/JavaScript/Packer.pm',
  VERSION_FROM  => 'lib/JavaScript/Packer.pm',
  AUTHOR        => 'Lee Johnson <leejo@cpan.org>',
  LICENSE       => 'perl',
  PREREQ_PM => {
    'Regexp::RegGrp'        => '1.001_001',
  },
  BUILD_REQUIRES => {
    'Test::More'               => 0,
  },
  META_MERGE => {
    resources => {
      license    => 'http://dev.perl.org/licenses/',
      homepage   => 'https://metacpan.org/module/JavaScript::Packer',
      bugtracker => 'https://github.com/leejo/javascript-packer-perl/issues',
      repository => 'https://github.com/leejo/javascript-packer-perl'
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
