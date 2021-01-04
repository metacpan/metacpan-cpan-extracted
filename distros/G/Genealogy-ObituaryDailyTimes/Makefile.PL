#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my $prereqs = {
	'autodie' => 0,
	'Carp' => 0,
	'DBD::SQLite' => 0,
	'Error::Simple' => 0,
	'File::Basename' => 0,
	'File::pfopen' => 0,
	'File::Spec' => 0,
	'File::Temp' => 0,
	'Module::Info' => 0
};

unless(defined($ENV{'AUTOMATED_TESTING'})) {
	$prereqs->{'DBI'} = 0;
	$prereqs->{'File::HomeDir'} = 0;
	$prereqs->{'HTML::Entities'} = 0;
	$prereqs->{'HTTP::Cache::Transparent'} = 0;
	$prereqs->{'LWP::ConnCache'} = 0;
	$prereqs->{'LWP::Protocol::https'} = 0;
	$prereqs->{'LWP::UserAgent::WithCache'} = 0;
	$prereqs->{'Lingua::EN::NameCase'} = 0;
	$prereqs->{'Try::Tiny'} = 0;
}

WriteMakefile(
	NAME		=> 'Genealogy::ObituaryDailyTimes',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Genealogy/ObituaryDailyTimes.pm',
	ABSTRACT_FROM	=> 'lib/Genealogy/ObituaryDailyTimes.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	'LIBS' => [''],   # e.g., '-lm'
	'DEFINE' => '',     # e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES => (defined($ENV{'AUTOMATED_TESTING'}) ? {} : {'bin/create_db.PL' => 'bin/create_db'}),
	TEST_REQUIRES => {
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		# 'Test::Kwalitee' => 0,
		'IPC::System::Simple' => 0,
	}, PREREQ_PM => $prereqs,
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'Genealogy-ObituaryDailyTimes-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Genealogy-ObituaryDailyTimes.git',
				web => 'https://github.com/nigelhorne/Genealogy-ObituaryDailyTimes',
				repository => 'https://github.com/nigelhorne/Genealogy-ObituaryDailyTimes',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-ObituaryDailyTimes',
				# mailto => 'bug-Genealogy-ObituaryDailyTimes@rt.cpan.org'
				web => 'https://github.com/nigelhorne/Genealogy-ObituaryDailyTimes/issues',
				mailto => 'bug-Genealogy-ObituaryDailyTimes@rt.cpan.org'
			}, homepage => 'https://sites.rootsweb.com/~obituary',
		},
	},
	# PPM_INSTALL_EXEC	=> 'perl',
	# PPM_INSTALL_SCRIPT	=> 'bin/create_db.PL',
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
