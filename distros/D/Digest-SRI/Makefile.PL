#!/usr/bin/env perl
use ExtUtils::MakeMaker 6.52;  # need >=6.52 for CONFIGURE_REQUIRES
# and in CONFIGURE_REQUIRES, we require >=6.64 for TEST_REQUIRES
WriteMakefile(
	NAME           => 'Digest::SRI',
	AUTHOR         => 'Hauke D <haukex@zero-g.net>',
	LICENSE        => 'gpl_3',
	VERSION_FROM   => 'lib/Digest/SRI.pm', # finds $VERSION
	ABSTRACT_FROM  => 'lib/Digest/SRI.pm',
	MIN_PERL_VERSION => '5.6.0',
	META_MERGE     => {
		'meta-spec'  => { version => 2 },
		resources    => {
			homepage    => 'https://github.com/haukex/Digest-SRI',
			repository  => {
				type       => 'git',
				url        => 'https://github.com/haukex/Digest-SRI.git',
				web        => 'https://github.com/haukex/Digest-SRI',
			},
			bugtracker  => {
				web        => 'https://github.com/haukex/Digest-SRI/issues',
				#mailto     => '',
			},
		},
		prereqs      => {
			runtime    => {
				recommends => { # "strongly encouraged and should be satisfied except in resource constrained environments"
				},
				suggests   => { # "optional, but are suggested for enhanced operation"
				},
			},
		},
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'    => '6.64',
	},
	PREREQ_PM      => {
		# CPAN - none
		# Perl core modules
		'Exporter'               => 0,
		'Carp'                   => 0,
		'Scalar::Util'           => 0,
		'Digest'                 => '1.03',
		'Digest::SHA'            => '6.00',
		'MIME::Base64'           => '3.10',
	},
	TEST_REQUIRES  => {
		# CPAN - none
		# Perl core modules
		'Test::More'             => '1.302096',
		'FindBin'                => 0,
		'File::Spec::Functions'  => 0,
		# note I haven't included modules needed for author tests here
	},
);
