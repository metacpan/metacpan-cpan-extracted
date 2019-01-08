#!/usr/bin/env perl
use ExtUtils::MakeMaker 6.52;  # need >=6.52 for CONFIGURE_REQUIRES
# and in CONFIGURE_REQUIRES, we require >=6.64 for TEST_REQUIRES
WriteMakefile(
	NAME           => 'File::Replace',
	AUTHOR         => 'Hauke D <haukex@zero-g.net>',
	LICENSE        => 'gpl_3',
	VERSION_FROM   => 'lib/File/Replace.pm', # finds $VERSION
	ABSTRACT_FROM  => 'lib/File/Replace.pm',
	MIN_PERL_VERSION => '5.8.1',
	META_MERGE     => {
		'meta-spec'  => { version => 2 },
		provides     => {
			'File::Replace' => {
				file    => 'lib/File/Replace.pm',
				version => '0.12',
			},
			'File::Replace::Inplace' => {
				file    => 'lib/File/Replace/Inplace.pm',
				version => '0.12',
			},
			'Tie::Handle::Base' => {
				file    => 'lib/Tie/Handle/Base.pm',
				version => '0.12',
			},
			'Tie::Handle::Argv' => {
				file    => 'lib/Tie/Handle/Argv.pm',
				version => '0.12',
			},
		},
		no_index     => {
			file      => [
					'lib/File/Replace/DualHandle.pm',
					'lib/File/Replace/SingleHandle.pm',
				],
		},
		resources    => {
			homepage    => 'https://bitbucket.org/haukex/file-replace',
			repository  => {
				type       => 'git',
				url        => 'https://bitbucket.org/haukex/file-replace.git',
				web        => 'https://bitbucket.org/haukex/file-replace',
			},
			bugtracker  => {
				web        => 'https://bitbucket.org/haukex/file-replace/issues',
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
		'Carp'                   => 0,
		'warnings::register'     => 0,
		'IO::Handle'             => 0,
		'Hash::Util'             => 0,
		'Scalar::Util'           => 0,
		'File::Temp'             => 0,
		'File::Basename'         => 0,
		'File::Spec::Functions'  => 0,
		'File::Copy'             => 0,
		'Fcntl'                  => 0,
		'Exporter'               => 0,
	},
	TEST_REQUIRES  => {
		# CPAN
		'IPC::Run3::Shell'       => '0.56',
		# Perl core modules
		'Encode'                 => 0,
		'Test::More'             => '1.302096',
		'FindBin'                => 0,
		'File::stat'             => 0,
		# note I haven't included modules needed for author tests here
	},
);
sub MY::postamble {
	return <<'MAKE_FRAG';
.PHONY: authorcover
authorcover: test
	cpanm Devel::Cover
	cover -test -coverage default,-pod
MAKE_FRAG
}
