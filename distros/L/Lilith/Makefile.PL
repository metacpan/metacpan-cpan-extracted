use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME               => 'Lilith',
	AUTHOR             => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM       => 'lib/Lilith.pm',
	ABSTRACT_FROM      => 'lib/Lilith.pm',
	LICENSE            => 'artistic_2',
	MIN_PERL_VERSION   => '5.006',
	INST_SCRIPT        => 'bin',
	EXE_FILES          => ['src_bin/lilith'],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'POE::Wheel::FollowTail' => '1.368',
		'TOML'                   => '0.97',
		'DBI'                    => '1.643',
		'JSON'                   => '0',
		'File::ReadBackwards'    => '0',
		'Digest::SHA'            => '0',
		'POE'                    => '0',
		'Sys::Hostname'          => '0',
		'File::Slurp'            => '0',
		'MIME::Base64'           => '0',
		'Gzip::Faster'           => '0',
		'DBD::Pg'                => '0',
		'Data::Dumper'           => '0',
		'Text::ANSITable'        => '0.608',
		'Net::Server::Daemonize' => '0',
		'Sys::Syslog'            => '0',
		'YAML::PP'               => '0',
		'File::Slurp'            => '0',
		'TOML'                   => '0',
		'Term::ANSIColor'        => '0',
		'MIME::Base64'           => '0',
		'Sys::Hostname'          => '0',
		'Time::Piece::Guess'     => '0',
	},
	dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean      => { FILES    => 'Lilith-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'git@github.com:LilithSec/Lilith.git',
				web  => 'https://github.com/LilithSec/Lilith',
			},
		},
	}
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
