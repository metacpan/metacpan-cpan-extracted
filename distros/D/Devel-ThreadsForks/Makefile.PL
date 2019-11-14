require 5.008;
use lib '.';
use ExtUtils::MakeMaker;
use Module::Metadata;
eval "use Devel::Required";

WriteMakefile (
 	NAME		=> "Devel::ThreadsForks",
	AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
	ABSTRACT	=> 'Check for availability of threads or forks',
	VERSION_FROM	=> 'lib/Devel/ThreadsForks.pm',
	LICENSE        => 'perl',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
		'Module::Metadata' => '1.000033',
		'Devel::Required' => '0',
	},
	BUILD_REQUIRES => {
		'Test::More' => '0',
		'Config' => '0'
	},
	PREREQ_PM => {
		'Config' => '0',
		'strict' => '0',
		'warnings' => '0'
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Devel-ThreadsForks-*' },
 	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/ThisUsedToBeAnEmail/Devel-ThreadsForks.git',
				web  => 'https://github.com/ThisUsedToBeAnEmail/Devel-ThreadsForks',
			}
		}
	},
	META_ADD => {
		provides => Module::Metadata->provides(version => '2', dir => 'lib')
	}
);


