use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

my %WriteMakefileArgs = (
	NAME               => 'Ixchel',
	AUTHOR             => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM       => 'lib/Ixchel.pm',
	ABSTRACT_FROM      => 'lib/Ixchel.pm',
	LICENSE            => 'gpl_3',
	MIN_PERL_VERSION   => '5.006',
	EXE_FILES          => ['src_bin/ixchel'],
	INST_SCRIPT        => 'bin',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'     => 0,
		'File::ShareDir::Install' => 0,
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'Config::Tiny'         => 0,
		'Data::Dumper'         => 0,
		'File::Find::Rule'     => 0,
		'File::ShareDir'       => 0,
		'File::Slurp'          => 0,
		'Hash::Merge'          => 0,
		'JSON'                 => 0,
		'JSON::Path'           => 0,
		'LWP::Simple'          => 0,
		'LWP::Protocol::https' => 0,
		'Module::List'         => 0,
		'Pod::Parser'          => 0,
		'Rex'                  => '1.14.3',
		'String::ShellQuote'   => 0,
		'TOML::Tiny'           => 0,
		'Template'             => '3.101',
		'YAML::XS'             => 0,
		'YAML::yq::Helper'     => '0.2.0',
	},
	dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean      => { FILES    => 'Ixchel-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'git@github.com:LilithSec/Ixchel.git',
				web  => 'https://github.com/LilithSec/Ixchel',
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

package MY;
use File::ShareDir::Install qw(postamble);
