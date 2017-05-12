#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME         => 'Lingua::Spelling::Alternative',
    AUTHOR       => 'Dobrica Pavlinusic <dpavlin@rot13.org>',
    ABSTRACT     => 'Produce all alternative forms of given word',
    VERSION_FROM => 'Alternative.pm',
    dist         => {
		COMPRESS => 'gzip -9f',
		SUFFIX   => 'gz',
	},
  );
