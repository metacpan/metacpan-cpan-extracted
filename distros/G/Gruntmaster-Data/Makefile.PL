use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Gruntmaster::Data',
	VERSION_FROM      => 'lib/Gruntmaster/Data.pm',
	ABSTRACT_FROM     => 'lib/Gruntmaster/Data.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES         => [qw/gm gruntmaster-opener/],
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Getopt::Long 0
		   PerlX::Maybe 0
		   POSIX 0
		   Term::ANSIColor 0

		   App::Cmd 0
		   Date::Parse 0
		   DBI 0
		   DBIx::Simple 0
		   DBD::Pg 0
		   File::Slurp 0
		   IO::Prompter 0
		   JSON::MaybeXS 0
		   PerlX::Maybe 0
		   SQL::Abstract 0/,
	},
	BUILD_REQUIRES    => {
		qw/Test::Deep 0/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=gruntmaster-data.git',
		}
	}
);
