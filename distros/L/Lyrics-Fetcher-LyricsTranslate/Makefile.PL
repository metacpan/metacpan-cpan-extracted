use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Lyrics::Fetcher::LyricsTranslate',
	VERSION_FROM      => 'lib/Lyrics/Fetcher/LyricsTranslate.pm',
	ABSTRACT_FROM     => 'lib/Lyrics/Fetcher/LyricsTranslate.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/HTML::Tree      0
		   Lyrics::Fetcher 0/,
	},
	TEST_REQUIRES     => {
		qw/Test::RequiresInternet 0/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=lyrics-fetcher-lyricstranslate.git',
		},
	}
);
