use v5.10.1;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME             => 'FTN::Crypt',
	VERSION_FROM     => 'lib/FTN/Crypt.pm',
	ABSTRACT_FROM    => 'lib/FTN/Crypt.pm',
	AUTHOR           => 'Petr Antonov',
	LICENSE          => 'perl',
	MIN_PERL_VERSION => '5.10.1',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Pod::Coverage'       => '0',
		'Test::CheckManifest' => '0',
		'Test::Data'          => '1.24',
		'Test::LongString'    => '0.17',
        'Test::More'          => '0.94',
        'Test::Pod'           => '0',
        'Test::Pod::Coverage' => '0',
    },
	PREREQ_PM        => {
		'strict'           => '0',
		'warnings'         => '0',
		'Try::Tiny'        => '0.28',
		'IO::Handle'       => '1.35',
		'FTN::Address'     => '1.04',
		'FTN::Nodelist'    => '1.08',
		'GnuPG::Interface' => '0.52',
		'PGP::Finger'      => '1.1',
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'FTN-Crypt-*' },
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		  'meta-spec' => { version => 2 },
		  resources => {
			  repository => {
				  type => 'git',
				  url  => 'https://github.com/pietro-a/FTN-Crypt.git',
				  web  => 'https://github.com/pietro-a/FTN-Crypt',
			  },
		  }})
		: ()
	),
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
