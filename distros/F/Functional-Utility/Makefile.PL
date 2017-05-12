use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Functional::Utility',
	AUTHOR              => 'Belden Lyman <belden@cpan.org>',
	VERSION_FROM        => 'lib/Functional/Utility.pm',
	ABSTRACT_FROM       => 'lib/Functional/Utility.pm',
	PL_FILES            => {},
	PREREQ_PM => {
    'Time::HiRes'      => 0,
  },
  META_MERGE => {
    resources => {
      bugtracker => 'https://github.com/belden/perl-functional-utility/issues',
    },
  },
	LICENSE => 'perl',
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => 'Functional-Utility-*' },
 );
