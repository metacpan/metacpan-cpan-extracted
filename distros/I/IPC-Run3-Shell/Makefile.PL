#!/usr/bin/env perl
use ExtUtils::MakeMaker 6.52;  # need >=6.52 for CONFIGURE_REQUIRES
# and in CONFIGURE_REQUIRES, we require >=6.64 for TEST_REQUIRES
WriteMakefile(
	NAME           => 'IPC::Run3::Shell',
	AUTHOR         => 'Hauke D <haukex@zero-g.net>',
	LICENSE        => 'perl',
	VERSION_FROM   => 'lib/IPC/Run3/Shell.pm', # finds $VERSION
	ABSTRACT_FROM  => 'lib/IPC/Run3/Shell.pod',
	MIN_PERL_VERSION => '5.6.0',
	META_MERGE     => {
		"meta-spec"  => { version => 2 },
		resources    => {
			homepage    => 'https://github.com/haukex/IPC-Run3-Shell',
			repository  => {
				type    => 'git',
				url     => 'https://github.com/haukex/IPC-Run3-Shell.git',
				web     => 'https://github.com/haukex/IPC-Run3-Shell',
			},
			bugtracker  => {
				web     => 'https://github.com/haukex/IPC-Run3-Shell/issues',
				#mailto  => '',
			},
		},
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'    => '6.64',
	},
	PREREQ_PM      => {
		# CPAN
		'IPC::Run3'              => 0,
		# Perl core modules
		'Carp'                   => 0,
		'Scalar::Util'           => 0,
		'Data::Dumper'           => 0,
		'warnings::register'     => 0,
		'overload'               => 0,
	},
	TEST_REQUIRES  => {
		# CPAN
		'Test::Fatal'            => 0,
		'Capture::Tiny'          => 0,
		# Perl core modules
		'Test::More'             => 0,
		'FindBin'                => 0,
		'File::Spec::Functions'  => 0,
		'File::Temp'             => 0,
		'Exporter'               => 0,
		'base'                   => 0,
		'Config'                 => 0,
		# note I haven't included modules needed for author tests here
	},
);
