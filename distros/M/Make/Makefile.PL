use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %config = (
	NAME         => 'Make',
	VERSION_FROM => 'lib/Make.pm',
	DISTNAME     => 'Make',
	(
		$] >= 5.005
		? (
			ABSTRACT_FROM => 'lib/Make.pm',
			AUTHOR        => 'Nick Ing-Simmons',
			)
		: ()
	),
	( $ExtUtils::MakeMaker::VERSION >= 6.3002
		? ( 'LICENSE' => 'perl' )
		: () ),

	clean => {
		FILES => "*% *.bak Make/*% *~"
	},
	dist => {
		COMPRESS => 'gzip -f',
		SUFFIX   => '.gz',
	},
	EXE_FILES => ['pmake'],
	(
		eval { ExtUtils::MakeMaker->VERSION(6.46) }
		? (
			META_MERGE => {
				'meta-spec' => { version => 2 },
				resources   => {
					repository => {
						type => 'git',
						url  => 'http://github.com/klp2/Make.git',
						web  => 'http://github.com/klp2/Make',
					},
					bugtracker => {
						web => 'http://github.com/klp2/Make/issues',
					},
					homepage => 'http://metacpan.org/pod/Make',
				},
			}
			)
		: ()
	)
);

my %test_requires = (
	'Test::More'    => 1,
	'Test::Compile' => '1.2.1',
	'Test::Pod'     => '1.00'
);

if ( eval { ExtUtils::MakeMaker->VERSION(6.64) } ) {
	$config{TEST_REQUIRES} = \%test_requires;
}
else {
	$config{BUILD_REQUIRES} = \%test_requires;
}

WriteMakefile(%config);
