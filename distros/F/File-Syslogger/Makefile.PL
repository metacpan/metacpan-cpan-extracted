use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME               => 'File::Syslogger',
	AUTHOR             => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM       => 'lib/File/Syslogger.pm',
	ABSTRACT_FROM      => 'lib/File/Syslogger.pm',
	LICENSE            => 'artistic_2',
	MIN_PERL_VERSION   => '5.006',
	INST_SCRIPT        => 'bin',
	EXE_FILES          => [ 'src_bin/filesyslogger', ],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'POE::Wheel::FollowTail' => '1.368',
		'TOML'                   => '0.97',
		'Log::Syslog::Fast'      => '0.67',
	},
	dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean      => { FILES    => 'File-Syslogger-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'git@github.com:VVelox/File-Syslogger.git',
				web  => 'https://github.com/VVelox/File-Syslogger',
			},
		},
	},

);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
	my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$test_requires } = values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
	my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$build_requires } = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
	unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
	unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
