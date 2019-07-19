#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'HTML::Packer',
  ABSTRACT_FROM => 'lib/HTML/Packer.pm',
  VERSION_FROM  => 'lib/HTML/Packer.pm',
  AUTHOR        => 'Lee Johnson <leejo@cpan.org>',
  LICENSE       => 'perl',
  PREREQ_PM => {
    'Regexp::RegGrp'        => '1.001_001',
    'CSS::Packer'           => "2.01",
    'JavaScript::Packer'    => "2.01",
	'Digest::SHA'           => 0, # core module
  },
  BUILD_REQUIRES => {
    'Test::More'               => 0,
  },
  META_MERGE => {
    resources => {
      license    => 'http://dev.perl.org/licenses/',
      homepage   => 'https://metacpan.org/module/HTML::Packer',
      bugtracker => 'https://github.com/leejo/html-packer-perl/issues',
      repository => 'https://github.com/leejo/html-packer-perl'
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
