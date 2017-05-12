use 5.016000;
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
	MIN_PERL_VERSION => '5.016000',
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
				url => 'git://github.com/igormunkin/Lingua-RU-Money-XS.git',
				web => 'https://github.com/igormunkin/Lingua-RU-Money-XS',
			},
		},
	},
	LIBS             => ['-lm'],
	DEFINE           => '',
	INC              => '-I.',
	H                => [ 'words.h' ],
	PL_FILES         => { 'words.h.PL' => 'words.h' },
	clean            => { FILES => 'words.h' },
);
