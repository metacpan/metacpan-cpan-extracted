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
	die 'Install File::Fetch >= 0.56 first';
}

if(version->parse($File::Fetch::VERSION) < 0.56) {
	die 'Install File::Fetch >= 0.56 first';
}

File::Fetch->import();
my %urls = (
	'http://download.geonames.org/export/dump/admin1CodesASCII.txt' => 'lib/Geo/Coder/Free/MaxMind/databases/admin1.db',
	'http://download.geonames.org/export/dump/admin2Codes.txt' => 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db',
	# 'https://geocode.nigelhorne.com/lib/Geo/Coder/Free/MaxMind/databases/cities.sql' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql',
	'http://download.maxmind.com/download/worldcities/worldcitiespop.txt.gz' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.csv.gz',
);


# unlink('lib/Geo/Coder/Free/MaxMind/databases/cities.sql');

foreach my $url(keys %urls) {
	next if(-r $urls{$url});
	print "Downloading $url\n";
	my $ff = File::Fetch->new(uri => $url);
	if(my $path = $ff->fetch($url)) {
		rename $path, $urls{$url};
	} elsif(my $err = $ff->error(1)) {
		die $err;
	} else {
		die "There was a problem downloading $url";
	}
}

if(open(my $admin2, '>>', 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db')) {
	print $admin2 "GB.ENG.E7\tLondon\tLondon\t2648110\n",
		"GB.ENG.H1\tLondon\tLondon\t2648110\n";
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
		'File::Basename' => 0,
		'File::Copy' => 0,
		'File::Spec' => 0,
		'autodie' => 0,
		'IPC::System::Simple' => 0,
		'JSON' => 0,
		'LWP::UserAgent::Throttled' => 0,
	},
	TEST_REQUIRES => {
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		'Test::Number::Delta' => 0,
		'Test::Carp' => 0,
	},
	PREREQ_PM => {
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
		# 'Text::xSV::Slurp' => 0,
		'Geo::StreetAddress::US' => 0,
		'Gzip::Faster' => 0,
		'File::Temp' => 0,
		'Module::Info' => 0,
		'File::Spec' => 0,
		'CHI' => 0,
		'Storable' => 0,
		'Text::CSV' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Free',
				mailto => 'bug-Geo-Coder-Free@rt.cpan.org'
			}
		},
	},
	# PPM_INSTALL_EXEC	=> 'bash',
	# PPM_INSTALL_SCRIPT	=> 'bin/createdatabase',
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
