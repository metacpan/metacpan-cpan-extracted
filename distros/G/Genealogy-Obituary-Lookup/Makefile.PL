#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

my @dirs;

if(defined($ENV{'GITHUB_ACTION'}) || defined($ENV{'CIRCLECI'}) || defined($ENV{'TRAVIS_PERL_VERSION'}) || defined($ENV{'APPVEYOR'})) {
	# Prevent downloading and installing stuff
	warn 'AUTOMATED_TESTING added for you' if(!defined($ENV{'AUTOMATED_TESTING'}));
	$ENV{'AUTOMATED_TESTING'} = 1;
	$ENV{'NO_NETWORK_TESTING'} = 1;
} elsif(!$ENV{'NO_NETWORK_TESTING'}) {
	push @dirs, 'lib/Genealogy/Obituary/Lookup/data';
}

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
	'constant' => 0,
	'Carp' => 0,
	'Data::Reuse' => 0,
	'Database::Abstraction' => 0.04,
	'DBD::SQLite' => 0,
	'DBD::SQLite::Constants' => 0,
	'Error::Simple' => 0,
	'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	'File::Basename' => 0,
	'File::pfopen' => 0,
	'File::Slurp' => 0,
	'File::Spec' => 0,
	'File::Temp' => 0,
	'Module::Info' => 0,
	'Object::Configure' => 0.10,
	'Params::Get' => 0.04,
	'Scalar::Util' => 0,
	'Text::CSV' => 0,
	'YAML::XS' => 0,
};

unless(defined($ENV{'NO_NETWORK_TESTING'})) {
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

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Genealogy::Obituary::Lookup',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Genealogy/Obituary/Lookup.pm',	# finds $VERSION in the module
	ABSTRACT_FROM	=> 'lib/Genealogy/Obituary/Lookup.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	'LIBS' => [''],   # e.g., '-lm'
	'DEFINE' => '',     # e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES => (defined($ENV{'AUTOMATED_TESTING'}) ? {} : {'bin/create_db.PL' => 'bin/create_db'}),
	TEST_REQUIRES => {
		'FindBin' => 0,
		'File::Temp' => 0,
		'Test::Carp' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		'Test::Needs' => 0,
		'Test::HTTPStatus' => 0,
		# 'Test::Kwalitee' => 0,
		'IPC::System::Simple' => 0,
		'YAML::XS' => 0
	}, PREREQ_PM => $prereqs,
	dist => $dist,
	clean => { FILES => 'Genealogy-Obituary-Lookup-*' },
	realclean => {
		FILES => 'Genealogy-Obituary-Lookup-* lib/Genealogy/Obituary-Lookup/data'
	},
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Genealogy::Obituary::Lookup',
			repository => {
				repository => 'https://github.com/nigelhorne/Genealogy-Obituary-Lookup',
				type => 'git',
				url => 'git://github.com/nigelhorne/Genealogy-Obituary-Lookup.git',
				web => 'https://github.com/nigelhorne/Genealogy-Obituary-Lookup',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Genealogy-Obituary-Lookup@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Genealogy-Obituary-Lookup/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Obituary-Lookup',
				web => 'https://github.com/nigelhorne/Genealogy-Obituary-Lookup/issues'
			}
		},
	},
	# PPM_INSTALL_EXEC	=> 'perl',
	# PPM_INSTALL_SCRIPT	=> 'bin/create_db.PL',
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
