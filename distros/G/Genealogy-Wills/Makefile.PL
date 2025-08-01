#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

# Test for broken smokers that don't set AUTOMATED_TESTING
if(my $reporter = $ENV{'PERL_CPAN_REPORTER_CONFIG'}) {
	if($reporter =~ /smoker/i) {
		warn 'AUTOMATED_TESTING added for you';
		$ENV{'AUTOMATED_TESTING'} = 1;
	}
}

my @dirs = (
	'lib/Genealogy/Wills/data'
);

# FIXME: AUTOMATED_TESTING - create the empty directory in blib
foreach my $dir(@dirs) {
	if(! -d $dir) {
		print "Creating the download directory $dir\n";
		mkdir $dir, 0755 || die "$dir: $@";
		if($ENV{'AUTOMATED_TESTING'}) {
			# So that the directory is copied to blib for testing
			open(my $dummy, '>', "$dir/dummy");
		}
	}
}

my $prereqs = {
	'autodie' => 0,
	'Carp' => 0,
	'Data::Reuse' => 0,
	'Database::Abstraction' => 0.04,
	'DBD::SQLite' => 0,
	'DBD::SQLite::Constants' => 0,
	'Error::Simple' => 0,
	'ExtUtils::MakeMaker' => 6.64,	# 6.64 for TEST_REQUIRES
	'File::Basename' => 0,
	'File::pfopen' => 0,
	'File::Slurp' => 0,
	'File::Spec' => 0,
	'File::Temp' => 0,
	'Module::Info' => 0,
	'Object::Configure' => 0.10,
	'Params::Get' => 0,
	'Return::Set' => 0,
	'Scalar::Util' => 0
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
	$prereqs->{'Test::HTTPStatus'} = 0;
	$prereqs->{'Try::Tiny'} = 0;
}

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Genealogy::Wills',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Genealogy/Wills.pm',
	ABSTRACT_FROM	=> 'lib/Genealogy/Wills.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	'LIBS' => [''],   # e.g., '-lm'
	'DEFINE' => '',     # e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES => (defined($ENV{'AUTOMATED_TESTING'}) ? {} : {'bin/create_db.PL' => 'bin/create_db'}),
	TEST_REQUIRES => {
		'File::Temp' => 0,
		'Test::Carp' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Warnings' => 0,
		# 'Test::Kwalitee' => 0,
		'IPC::System::Simple' => 0,
		'YAML::Any' => 0
	}, PREREQ_PM => $prereqs,
	dist => $dist,
	clean => { FILES => 'Genealogy-Wills-*' },
	realclean => {
		FILES => 'Genealogy-Wills-* lib/Genealogy/Wills/data'
	},
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Genealogy-Wills.git',
				web => 'https://github.com/nigelhorne/Genealogy-Wills',
				repository => 'https://github.com/nigelhorne/Genealogy-Wills',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Wills',
				# mailto => 'bug-Genealogy-Wills@rt.cpan.org'
				web => 'https://github.com/nigelhorne/Genealogy-Wills/issues',
				mailto => 'bug-Genealogy-Wills@rt.cpan.org'
			}, homepage => 'https://sites.rootsweb.com/~obituary',
		},
	},
	# PPM_INSTALL_EXEC	=> 'perl',
	# PPM_INSTALL_SCRIPT	=> 'bin/create_db.PL',
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
