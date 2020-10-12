#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my @needfull;

# Install Pre-requisites
BEGIN {
	my @modules = (
		'LWP::Protocol::https', 'LWP::Simple'
	);

	foreach my $module(@modules) {
		eval "use $module";
		if($@) {
			push @needfull, $module;
		}
	}

	if(scalar(@needfull)) {
		my $list = join(' ', @needfull);
		if($ENV{'AUTOMATED_TESTING'}) {
			die "You need $list to test this package";
		}
		print "Installing $list\n";
		system("cpan -i $list");
	}
}

foreach my $module(@needfull) {
	my $version;
	if($module =~ /(.+)\s(.+)$/) {
		$module = $1;
		$version = $2;
	}
	if($module =~ /.+\/(.+)/) {
		$module = $1;
	}
	eval "require $module";
	if($@) {
		die $@;
	}
	$module->import();
	# if($version && ($module::VERSION < $version)) {
		# die "$module: need $version got ", $module::VERSION;
	# }
}

if(eval { require Geo::libpostal; }) {
	my $v = Geo::libpostal->VERSION;
	print "You have Geo::libpostal version $v installed, so Geo-Coder-Free can work better\n";
} else {
	print "Consider installing Geo::libpostal for improved parsing\n";
}

my @dirs = (
	'lib/Geo/Coder/Free/GeoNames',
	'lib/Geo/Coder/Free/GeoNames/databases',
	'lib/Geo/Coder/Free/MaxMind',
	'lib/Geo/Coder/Free/MaxMind/databases'
);

foreach my $dir(@dirs) {
	if(! -d $dir) {
		print "Creating the download directory $dir\n";
		mkdir $dir || die "$dir: $@";
	}
}

my %urls = (
	'http://download.geonames.org/export/dump/admin1CodesASCII.txt' => 'lib/Geo/Coder/Free/MaxMind/databases/admin1.db',
	'http://download.geonames.org/export/dump/admin2Codes.txt' => 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db',
	# 'https://geocode.nigelhorne.com/lib/Geo/Coder/Free/MaxMind/databases/cities.sql' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql',
	# 'http://download.maxmind.com/download/worldcities/worldcitiespop.txt.gz' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.csv.gz',
	# This data are 7 years out of date, and are unconsistent with the Geonames database
	'https://github.com/apache/commons-csv/blob/master/src/test/resources/org/apache/commons/csv/perf/worldcitiespop.txt.gz?raw=true' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.csv.gz',
	'http://download.geonames.org/export/dump/allCountries.zip' => 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.zip',
);

# unlink('lib/Geo/Coder/Free/MaxMind/databases/cities.sql');
if(eval { require HTTP::Cache::Transparent; }) {
	HTTP::Cache::Transparent->import();
	my $cachedir;
	if(my $e = $ENV{'CACHEDIR'}) {
		$cachedir = File::Spec->catfile($e, 'http-cache-transparent');
	} else {
		$cachedir = File::Spec->catfile(File::Spec->tmpdir(), 'cache', 'http-cache-transparent');
	}

	HTTP::Cache::Transparent::init({
		BasePath => $cachedir,
		# Verbose => $opts{'v'} ? 1 : 0,
		Verbose => 1,
		NoUpdate => 60 * 60 * 24,
		MaxAge => 30 * 24
	}) || die "$0: $cachedir: $!";
} else {
	print "Consider installing HTTP::Cache::Transparent to reduce downloads\n";
}

foreach my $url(keys %urls) {
	my $file = $urls{$url};
	if(-r $file) {
		# Don't bother downloading if the file is less than a week old
		next if(-M $file < 7);
	}

	print "Downloading $url to $file\n";
	if(is_error(my $rc = mirror($url, $file))) {
		die "$url: LWP error $rc";
	}
	die $file if(!-r $file);
}

if(!(-r 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.txt')) {
	my $zip = 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.zip';
	system("unzip $zip");
	rename 'allCountries.txt', 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.txt';
	# Save disc space, but prevent more than one download
	if(open(my $fout, '>', $zip)) {
		close($fout);
	}
}

# London's areas are not complete within Maxmind.  Here are a few to get started
# To add more, look in lib/Geo/Coder/Free/MaxMind/databases/cities.csv and look for
#	the country/town and use the region code in there
if(open(my $admin2, '>>', 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db')) {
	print $admin2 "GB.ENG.E7\tWoolwich\tWoolwich\t2648110\n",
		"GB.ENG.O5\tLondon\tLondon\t2648110\n",
		"GB.ENG.I8\tLondon\tLondon\t2648110\n",
		"GB.ENG.P5\tLondon\tLondon\t2648110\n",
		"GB.ENG.G5\tTooting\tTooting\t2648110\n",	# Not in the database, but Balham is close
		"GB.ENG.A5\tBedfordshire\tBedfordshire\t2648110\n";
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
	$test_requires->{'CGI::ACL'} = 0;
	$test_requires->{'FCGI'} = 0;
	$test_requires->{'FCGI::Buffer'} = 0;
	$test_requires->{'HTML::SocialMedia'} = 0;
	$test_requires->{'Log::Any::Adapter::Log4perl'} = 0;
	$test_requires->{'Log::WarnDie'} = 0;
	$test_requires->{'IPC::System::Simple'} = 0;
	$test_requires->{'Template::Plugin::EnvHash'} = 0;
	$test_requires->{'Test::Pod::LinkCheck'} = 0;
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
	BUILD_REQUIRES => {	# For bin/create_sqlite
		'App::csv2sqlite' => 0,
		'CHI' => 0,
		'CHI::Driver::RawMemory' => 0,
		'Cwd' => 0,
		'Config::Auto' => 0,
		'File::Basename' => 0,
		'File::Copy' => 0,
		'File::Open::NoCache::ReadOnly' => 0.02,
		'File::Slurp' => 0,
		'File::Spec' => 0,
		'autodie' => 0,
		'Geo::Coder::Abbreviations' => 0.03,
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
	# PPM_INSTALL_SCRIPT	=> 'bin/create_sqlite',
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
