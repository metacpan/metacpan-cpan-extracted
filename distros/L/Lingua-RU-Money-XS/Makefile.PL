use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Lingua::RU::Money::XS',
	VERSION_FROM     => 'lib/Lingua/RU/Money/XS.pm',
	ABSTRACT_FROM    => 'lib/Lingua/RU/Money/XS.pm',
	BUILD_REQUIRES   => {
		Encode                => 2,
		'ExtUtils::MakeMaker' => 0,
		'List::MoreUtils'     => 0,
		'Test::Exception'     => 0,
		'Test::Spec'          => 0,
	},
	AUTHOR           => 'Igor Munkin <imun@cpan.org>',
	LICENSE          => 'perl',
	MIN_PERL_VERSION => '5.010000',
	META_MERGE       => {
		'meta-spec' => {
			version => 2,
		},
		resources => {
			license    => 'http://dev.perl.org/licenses/',
			bugtracker => {
				web    => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-RU-Money-XS',
				mailto => 'imun@cpan.org',
			},
			repository => {
				type => 'git',
				url => 'https://git.imun.cloud/p5-Lingua-RU-Money-XS.git',
				web => 'https://git.imun.cloud/p5-Lingua-RU-Money-XS.git',
			},
		},
	},
	LIBS             => ['-lm'],
	DEFINE           => '-g -ggdb -O2 -Wall -Wextra',
	INC              => '-I.',
	H                => [ 'words.h' ],
	PL_FILES         => { 'words.h.PL' => 'words.h' },
	dist             => {
		COMPRESS => 'gzip -9f',
		SUFFIX => 'gz',
		PREOP => q(perldoc -uT $(VERSION_FROM) \
			| tee $(DISTVNAME)/README.pod > README.pod; \
			pod2text README.pod | tee $(DISTVNAME)/README > README
		),
	},
	clean            => { FILES => 'words.h' },
);
