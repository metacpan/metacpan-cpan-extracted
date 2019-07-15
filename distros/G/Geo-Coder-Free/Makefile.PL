#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use version;

if(eval { require Geo::libpostal; }) {
	my $v = Geo::libpostal->VERSION;
	print "You have Geo::libpostal version $v installed, so Geo-Coder-Free can work better\n";
} else {
	print "Consider installing Geo::libpostal for improved parsing\n";
}

unless(eval { require File::Fetch; }) {
	if($ENV{'AUTOMATED_TESTING'}) {
		# This probably isn't the way to do it - need to find documentation
		print STDERR "UNKNOWN: Needs File::Fetch >= 0.56";
		exit;
	}
	die 'Install File::Fetch >= 0.56 first';
}

if(version->parse($File::Fetch::VERSION) < 0.56) {
	if($ENV{'AUTOMATED_TESTING'}) {
		print STDERR "UNKNOWN: Needs File::Fetch >= 0.56";
		exit;
	}
	die 'Install File::Fetch >= 0.56 first';
}

(-d 'lib/Geo/Coder/Free/GeoNames') || mkdir 'lib/Geo/Coder/Free/GeoNames';
(-d 'lib/Geo/Coder/Free/GeoNames/databases') || mkdir 'lib/Geo/Coder/Free/GeoNames/databases';

File::Fetch->import();
my %urls = (
	'http://download.geonames.org/export/dump/admin1CodesASCII.txt' => 'lib/Geo/Coder/Free/MaxMind/databases/admin1.db',
	'http://download.geonames.org/export/dump/admin2Codes.txt' => 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db',
	# 'https://geocode.nigelhorne.com/lib/Geo/Coder/Free/MaxMind/databases/cities.sql' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql',
	# 'http://download.maxmind.com/download/worldcities/worldcitiespop.txt.gz' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.csv.gz',
	# This data are 7 years out of date, and are unconsistent with the Geonames database
	'https://github.com/apache/commons-csv/blob/master/src/test/resources/perf/worldcitiespop.txt.gz?raw=true' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.csv.gz',
	'http://download.geonames.org/export/dump/allCountries.zip' => 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.zip',
);

# unlink('lib/Geo/Coder/Free/MaxMind/databases/cities.sql');

foreach my $url(keys %urls) {
	next if(-r $urls{$url});
	print "Downloading $url\n";
	my $ff = File::Fetch->new(uri => $url);
	if(my $path = $ff->fetch($url)) {
		print "Moving $path to $urls{$url}\n";
		rename $path, $urls{$url} or die "$urls{$url}: $!";
	} elsif(my $err = $ff->error(1)) {
		die $err;
	} else {
		die "There was a problem downloading $url";
	}
}

if(!(-r 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.txt')) {
	system('unzip lib/Geo/Coder/Free/GeoNames/databases/allCountries.zip');
	rename 'allCountries.txt', 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.txt';
}

# London's areas are not complete within Maxmind.  Here are a few to get started
if(open(my $admin2, '>>', 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db')) {
	print $admin2 "GB.ENG.E7\tWoolwich\tWoolwich\t2648110\n",
		"GB.ENG.O5\tLondon\tLondon\t2648110\n",
		"GB.ENG.I8\tLondon\tLondon\t2648110\n",
		"GB.ENG.P5\tLondon\tLondon\t2648110\n";
}

my $test_requires = {
	'CGI::IDS' => 0,
	'CGI::Lingua' => 0,
	'Data::Throttler' => 0,
	'Test::Carp' => 0,
	'Test::Deep' => 0,
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::Number::Delta' => 0
};

if($ENV{'AUTHOR_TESTING'}) {
	$test_requires->{'IPC::System::Simple'} = 0;
	$test_requires->{'FCGI::Buffer'} = 0;
	$test_requires->{'Log::WarnDie'} = 0;
}

WriteMakefile(
	NAME		=> 'Geo::Coder::Free',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Geo/Coder/Free.pm',
	ABSTRACT_FROM   => 'lib/Geo/Coder/Free.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	BUILD_REQUIRES => {	# For bin/createdatabase
		'App::csv2sqlite' => 0,
		'CHI' => 0,
		'CHI::Driver::RawMemory' => 0,
		'Config::Auto' => 0,
		'File::Basename' => 0,
		'File::Copy' => 0,
		'File::Open::NoCache::ReadOnly' => 0,
		'File::Spec' => 0,
		'autodie' => 0,
		'Geo::Location::Point' => 0.02,
		'IO::AIO' => 0,
		'IPC::System::Simple' => 0,
		'JSON' => 0,
		'LWP::UserAgent::Throttled' => 0,
		'Try::Tiny' => 0,
	},
	TEST_REQUIRES => $test_requires,
	PREREQ_PM => {
		'Carp' => 0,
		'DBI' => 0,
		'Digest::MD5' => 0,
		'File::pfopen' => '0.02',
		'DBD::CSV' => 0,
		'DBD::SQLite' => 0,
		'Encode' => 0,
		'List::MoreUtils' => 0,
		'Locale::Country' => 0,
		'Locale::CA' => 0,
		'Locale::SubCountry' => 0,
		'Locale::US' => 0,
		'Lingua::EN::AddressParse' => 0,
		'Geo::StreetAddress::US' => 0,
		'Gzip::Faster' => 0,
		'File::Temp' => 0,
		'Module::Info' => 0,
		'File::Spec' => 0,
		'CHI' => 0,
		'Storable' => 0,
		'Text::CSV' => 0,
		'Text::xSV::Slurp' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	clean		=> { FILES => 'Geo-Coder-Free-*' },
	# META_ADD => {
		# provides => {
			# 'Geo::Coder::Free' => {
				# version => '0.05',
				# file => 'Free.pm',
			# },
			# 'Geo::Coder::Free::MaxMind' => {
				# version => '0.01',
				# file => 'MaxMind.pm',
			# },
			# 'Geo::Coder::Free::OpenAddresses' => {
				# version => '0.01',
				# file => 'OpenAddresses.pm',
			# }
		# }
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Geo-Coder-Free.git',
				web => 'https://github.com/nigelhorne/Geo-Coder-Free',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Free',
				web => 'https://github.com/nigelhorne/Geo-Coder-Free/issues',
				mailto => 'bug-Geo-Coder-Free@rt.cpan.org'
			}
		},
	},
	# PPM_INSTALL_EXEC	=> 'bash',
	# PPM_INSTALL_SCRIPT	=> 'bin/createdatabase',
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
