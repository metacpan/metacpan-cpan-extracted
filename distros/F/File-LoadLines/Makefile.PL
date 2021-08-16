#! perl

# Ease the life of the CPAN testers.
use v5.10.1;

use strict;
use warnings;

# Need EU::MM that understands *_REQUIRES.
use ExtUtils::MakeMaker 6.76;

WriteMakefile
(
  NAME				=> 'File::LoadLines',
  AUTHOR			=> 'Johan Vromans <jv@cpan.org>',
  VERSION_FROM			=> 'lib/File/LoadLines.pm',
  ABSTRACT_FROM			=> 'lib/File/LoadLines.pm',
  LICENSE			=> 'perl_5',
  PL_FILES			=> {},
  MIN_PERL_VERSION		=> v5.10.1,

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'	=> 6.76,
  },

#  BUILD_REQUIRES => { 
#  },

  TEST_REQUIRES  => {
    'Test::More'		=> 0,
    'Test::Exception'		=> 0,
  },

  META_MERGE => {
    resources    => {
      repository => 'https://github.com/sciurius/perl-File-LoadLines',
      bugtracker => "https://github.com/sciurius/perl-File-LoadLines/issues",
    },
    'meta-spec' => {
      version => '2',
	url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
    },
  }
);
