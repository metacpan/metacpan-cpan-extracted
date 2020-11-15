#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::EN::NameCase',
    # AUTHOR              => 'Barbie <barbie@cpan.org>',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/Lingua/EN/NameCase.pm',
    ABSTRACT            => "Correctly case a person's name from UPERCASE or lowcase",
    LICENSE             => 'artistic_2',
    PL_FILES            => {},
    NO_META             => 1,
    PREREQ_PM => {

        'Carp'                  => '0',
        'Exporter'              => '0',

        # build/test prereqs
        'IO::File'              => '0',
        'Test::More'            => '0.70'
	}, TEST_REQUIRES => {
		'Test::Most' => 0,
	},
    'LIBS'              => [''],   # e.g., '-lm'
    'DEFINE'            => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'               => '',     # e.g., '-I/usr/include/other'
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Lingua-EN-NameCase.git',
				web => 'https://github.com/nigelhorne/Lingua-EN-NameCase',
				repository => 'https://github.com/nigelhorne/Lingua-EN-NameCase',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-EN-NameCase',
				# mailto => 'bug-Lingua-EN-NameCase@rt.cpan.org'
				web => 'https://github.com/nigelhorne/Lingua-EN-NameCase/issues',
				url => 'https://github.com/nigelhorne/Lingua-EN-NameCase/issues',
			}

		},
	},
);
