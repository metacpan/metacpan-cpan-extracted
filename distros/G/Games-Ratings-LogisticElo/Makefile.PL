use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Games::Ratings::LogisticElo',
	VERSION_FROM      => 'lib/Games/Ratings/LogisticElo.pm',
	ABSTRACT_FROM     => 'lib/Games/Ratings/LogisticElo.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Games::Ratings 0/,
	},
	META_ADD           => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=games-ratings-logisticelo.git',
		},
	}
);
