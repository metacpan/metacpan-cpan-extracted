use 5.010001;
use ExtUtils::MakeMaker;

my $has_tr = $ExtUtils::MakeMaker::VERSION >= 6.64;

WriteMakefile(
	NAME              => 'Mafia',
	VERSION_FROM      => 'lib/Mafia.pm',
	ABSTRACT_FROM     => 'lib/Mafia.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.10.1',
	LICENSE           => 'perl',
	SIGN              => 1,
	(TEST_REQUIRES => {
		qw/File::Spec::Functions 3.62/,
	}) x $has_tr,
	(PREREQ_PM => {
		qw/File::Spec::Functions 3.62/,
	}) x !$has_tr,
	META_MERGE         => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=mafia.git',
		}
	}
);
