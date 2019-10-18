use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Debug::Filter::PrintExpr',
    AUTHOR           => q{Jörg Sommrey <git@sommrey.de>},
    VERSION_FROM     => 'lib/Debug/Filter/PrintExpr.pm',
    ABSTRACT_FROM    => 'lib/Debug/Filter/PrintExpr.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
		'Test2::V0' => 0,
		'IO::String' => 0,
    },
    PREREQ_PM => {
		'Filter::Simple' => 0,
		'Data::Dumper' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Debug-Filter-PrintExpr-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources => {
			bugtracker => {
				web => 'https://github.com/jo-37/debug-filter-printexpr/issues',
			},
			repository => {
				type => 'git',
				url => 'git://github.com/jo-37/debug-filter-printexpr.git',
				web => 'https://github.com/jo-37/debug-filter-printexpr',
			},
		},
	},
);
