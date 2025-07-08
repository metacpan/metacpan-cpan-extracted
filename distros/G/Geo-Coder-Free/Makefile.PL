#!/usr/bin/env perl

# yum install libaio-devel

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my @needfull;

# Install Pre-requisites
BEGIN {
	my @modules = (
		'LWP::Protocol::https'
	);

	foreach my $module(@modules) {
		eval "use $module";
		if($@) {
			push @needfull, $module;
		}
	}

	# Test for broken smokers that don't set AUTOMATED_TESTING
	if(my $reporter = $ENV{'PERL_CPAN_REPORTER_CONFIG'}) {
		if($reporter =~ /smoker/i) {
			warn 'AUTOMATED_TESTING added for you' if(!defined($ENV{'AUTOMATED_TESTING'}));
			$ENV{'AUTOMATED_TESTING'} = 1;
			$ENV{'NO_NETWORK_TESTING'} = 1;
		}
	}

	if(scalar(@needfull)) {
		my $list = join(' ', @needfull);
		if($ENV{'AUTOMATED_TESTING'} &&
		  !defined($ENV{'TRAVIS_PERL_VERSION'}) &&
		  !defined($ENV{'GITHUB_ACTION'})) {
			print STDERR "NA: You need $list to test this package\n";
			exit(0);
		}
		print "Installing $list\n";
		# system("cpan -i $list");
		system('perl -MCPAN -e \'CPAN::Shell->install("' . join('", "', @needfull) . '")\'');
	}
}

if(defined($ENV{'GITHUB_ACTION'}) || defined($ENV{'CIRCLECI'}) || defined($ENV{'TRAVIS_PERL_VERSION'}) || defined($ENV{'APPVEYOR'})) {
	# Prevent downloading and installing stuff
	warn 'AUTOMATED_TESTING added for you' if(!defined($ENV{'AUTOMATED_TESTING'}));
	$ENV{'AUTOMATED_TESTING'} = 1;
	$ENV{'NO_NETWORK_TESTING'} = 1;
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
	'downloads',
	# 'lib/Geo/Coder/Free/GeoNames',
	# 'lib/Geo/Coder/Free/GeoNames/databases',
	'lib/Geo/Coder/Free/MaxMind',
	'lib/Geo/Coder/Free/MaxMind/databases',
);

foreach my $dir(@dirs) {
	if(! -d $dir) {
		print "Creating the download directory $dir\n";
		mkdir $dir, 0755 || die "$dir: $@";
	}
}

my %urls;
my $use_withcache;

if(!$ENV{'NO_NETWORK_TESTING'}) {
	%urls = (
		'http://download.geonames.org/export/dump/admin1CodesASCII.txt' => 'lib/Geo/Coder/Free/MaxMind/databases/admin1.db',
		'http://download.geonames.org/export/dump/admin2Codes.txt' => 'lib/Geo/Coder/Free/MaxMind/databases/admin2.db',
		# 'https://geocode.nigelhorne.com/lib/Geo/Coder/Free/MaxMind/databases/cities.sql' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql',
		# 'http://download.maxmind.com/download/worldcities/worldcitiespop.txt.gz' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.csv.gz',
		# This data are 7 years out of date, and are unconsistent with the Geonames database
		'https://github.com/apache/commons-csv/blob/master/src/test/resources/org/apache/commons/csv/perf/worldcitiespop.txt.gz?raw=true' => 'lib/Geo/Coder/Free/MaxMind/databases/cities.csv.gz',
		# 'http://download.geonames.org/export/dump/allCountries.zip' => 'lib/Geo/Coder/Free/GeoNames/databases/allCountries.zip',
		'http://download.geonames.org/export/dump/allCountries.zip' => 'downloads/allCountries.zip',
	);

	# unlink('lib/Geo/Coder/Free/MaxMind/databases/cities.sql');
	if(eval { require HTTP::Cache::Transparent; }) {
		HTTP::Cache::Transparent->import();
		my $cache_dir;
		if(my $e = $ENV{'CACHE_DIR'}) {
			$cache_dir = File::Spec->catfile($e, 'http-cache-transparent');
		} else {
			require File::HomeDir;
			File::HomeDir->import();

			# $cache_dir = File::Spec->catfile(File::Spec->tmpdir(), 'cache', 'http-cache-transparent');
			$cache_dir = File::Spec->catfile(File::HomeDir->my_home(), '.cache', 'http-cache-transparent');
		}

		if(!-d $cache_dir) {
			print "Creating the cache directory $cache_dir\n";
			mkdir $cache_dir, 02755 || die "$cache_dir: $@";
		}
		HTTP::Cache::Transparent::init({
			BasePath => $cache_dir,
			# Verbose => $opts{'v'} ? 1 : 0,
			Verbose => 1,
			NoUpdate => 60 * 60 * 24,
			MaxAge => 30 * 24
		}) || die "$0: $cache_dir: $!";
	} else {
		print "Consider installing HTTP::Cache::Transparent to reduce downloads\n";
	}

	if(eval { require LWP::Simple::WithCache; }) {
		LWP::Simple::WithCache->import();
		$use_withcache = 1;
	} else {
		require LWP::Simple;
		LWP::Simple->import();

		print "Consider installing LWP::Simple::WithCache to reduce downloads\n";
	}
}

my $pm;
if(scalar(keys(%urls)) > 1) {
	if(eval { require Parallel::ForkManager; }) {
		Parallel::ForkManager->import();

		$pm = Parallel::ForkManager->new(10);
	} else {
		print "Consider installing Parallel::Forkmanager to speed up downloads\n";
	}
}

foreach my $url(keys %urls) {
	my $file = $urls{$url};
	my $use_mirror = 0;

	if(-r $file) {
		# Don't bother checking for a download if the file is less than a week old
		next if(-M $file < 7);
		# I get errors with mirror with L:S:WithCache
		#	that the temporary file is unavailable
		if(!$use_withcache) {
			# Only download if a newer version is available
			$use_mirror = 1;
		}
	}

	$pm->start() and next if($pm);

	if($use_mirror) {
		print "Downloading $url to $file if a newer version is available\n";
		if($use_withcache &&
		   LWP::Simple::WithCache::is_error(my $rc = LWP::Simple::WithCache::mirror($url, $file))) {
			if($ENV{'AUTOMATED_TESTING'}) {
				print STDERR "Can't download $url";
				exit(0);
			}
			die "$url: LWP error $rc";
		} elsif(LWP::Simple::is_error($rc = LWP::Simple::mirror($url, $file))) {
			if($ENV{'AUTOMATED_TESTING'}) {
				print STDERR "Can't download $url";
				exit(0);
			}
			die "$url: LWP error $rc";
		}
	} else {
		print "Downloading $url to $file\n";
		if($use_withcache &&
		   LWP::Simple::WithCache::is_error(my $rc = LWP::Simple::WithCache::getstore($url, $file))) {
			if($ENV{'AUTOMATED_TESTING'}) {
				print STDERR "Can't download $url";
				exit(0);
			}
			die "$url: LWP error $rc";
		} elsif(LWP::Simple::is_error($rc = LWP::Simple::getstore($url, $file))) {
			if($ENV{'AUTOMATED_TESTING'}) {
				print STDERR "Can't download $url";
				exit(0);
			}
			die "$url: LWP error $rc";
		}
	}
	die $file if(!-r $file);
	$pm->finish() if($pm);
}

my $zip = 'downloads/allCountries.zip';

$pm->wait_all_children() if($pm);

if((!(-r 'downloads/allCountries.txt')) && (-r $zip)) {
	print "Inflating $zip\n";

	eval 'require IO::Uncompress::Unzip';
	if($@) {
		system("unzip $zip") or die "unzip $zip failed";
		rename 'allCountries.txt', 'downloads/allCountries.txt';
		# Save disc space, but prevent more than one download
		# if(open(my $fout, '>', $zip)) {
			# close($fout);
		# }
	} elsif(open(my $fout, '>', 'downloads/allCountries.txt')) {
		IO::Uncompress::Unzip->import();
		if(my $fin = IO::Uncompress::Unzip->new($zip)) {
			do {
				if($fin->getHeaderInfo->{'Name'} eq 'allCountries.txt') {
					while(my $line = $fin->getline()) {
						print $fout $line;
					}
					# last; # Gives syntax error that it's not in a loop :-(
				}
			} while($fin->nextStream());
		} elsif($ENV{'AUTOMATED_TESTING'}) {
			print STDERR "$zip: $IO::Uncompress::Unzip::UnzipError\n";
			exit(0);
		} else {
			die "$zip: $IO::Uncompress::Unzip::UnzipError";
		}
		close $fout || die "$zip: $!";
	}
	truncate $zip, 0;
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

# For bin/create_sqlite
my $build_requires = {
	'App::csv2sqlite' => 0,
	'CHI' => 0,
	'CHI::Driver::RawMemory' => 0,
	'Cwd' => 0,
	'Config::Abstraction' => 0,
	'Database::Abstraction' => 0,
	'Devel::Size' => 0,
	'File::Basename' => 0,
	'File::Copy' => 0,
	'File::Find' => 0,
	'File::Slurp' => 0,
	'File::Spec' => 0,
	'autodie' => 0,
	'Geo::Coder::Abbreviations' => 0.03,
	'Geo::Location::Point' => 0.14,
	'IPC::System::Simple' => 0,
	'JSON::MaybeXS' => 0,
	'LWP::ConnCache' => 0,
	'LWP::UserAgent::Throttled' => 0,
	'LWP::Protocol::https' => 0,
	'Scalar::Util' => 0,
	'Try::Tiny' => 0
};

if(($^O ne 'solaris') && ($^O ne 'haiku') && ($^O ne 'MSWin32')) {
	$build_requires->{'File::Open::NoCache::ReadOnly'} = 0.02;
	$build_requires->{'IO::AIO'} = 0;
}
if($ENV{'OSM_HOME'}) {
	$build_requires->{'XML::LibXML::Reader'} = 0;
}
if($ENV{'REDIS_SERVER'}) {
	$build_requires->{'Redis'} = 0;
}

my $test_requires = {
	'CGI::IDS' => 0,
	'CGI::Lingua' => 0,
	'CHI::Driver::Null' => 0,
	'Data::Throttler' => 0,
	'Test::Carp' => 0,
	'Test::Deep' => 0,
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0,
	'Test::NoWarnings' => 0,
	'Test::Number::Delta' => 0
};

if($ENV{'AUTHOR_TESTING'}) {
	$test_requires->{'CGI::ACL'} = 0;
	$test_requires->{'CGI::Carp'} = 0;
	$test_requires->{'Class::Simple'} = 0;
	$test_requires->{'FCGI'} = 0;
	$test_requires->{'FCGI::Buffer'} = 0;
	$test_requires->{'HTML::SocialMedia'} = 0;
	$test_requires->{'Log::Any::Adapter::Log4perl'} = 0;
	$test_requires->{'Log::WarnDie'} = 0;
	$test_requires->{'IPC::System::Simple'} = 0;
	$test_requires->{'Template::Filters'} = 0;
	$test_requires->{'Template::Plugin::EnvHash'} = 0;
	$test_requires->{'Test::Pod::LinkCheck'} = 0;
	$test_requires->{'Taint::Runtime'} = 0;
}

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
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
	BUILD_REQUIRES => $build_requires,
	TEST_REQUIRES => $test_requires,
	PREREQ_PM => {
		'Carp' => 0,
		# 'BerkeleyDB' => 0,
		'Cwd' => 0,
		'Data::Dumper' => 0,
		'Data::Validate::URI' => 0,
		'DB_File' => 0,
		'DBI' => 0,
		'Digest::MD5' => 0,
		'File::pfopen' => '0.02',
		'DBD::CSV' => 0,
		'DBD::SQLite' => 0,
		'Encode' => 0,
		'Locale::Country' => 0,
		'Locale::AU' => 0,
		'Locale::CA' => 0,
		'Locale::SubCountry' => 0,
		'Locale::US' => 0,
		'Lingua::EN::AddressParse' => 0,
		'Geo::Hash' => 0,
		'Geo::StreetAddress::US' => 0,
		'Gzip::Faster' => 0,
		'File::Temp' => 0,
		'Module::Info' => 0,
		'File::Spec' => 0,
		'CHI' => 0,
		'Object::Configure' => 0,
		'Params::Get' => 0,
		'Scalar::Util' => 0,
		'Storable' => 0,
		'Text::CSV' => 0,
		'Text::xSV::Slurp' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Geo-Coder-Free-*' },
	EXE_FILES => [ 'bin/address_lookup' ],
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
			# 'Geo::Coder::Free::Local' => {
				# version => '0.01',
				# file => 'Local.pm',
			# }
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
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Free',
				web => 'https://github.com/nigelhorne/Geo-Coder-Free/issues',
				mailto => 'bug-Geo-Coder-Free@rt.cpan.org'
			}, homepage => 'https://geocode.nigelhorne.com'
		},
	},
	# PL_FILES => (defined($ENV{'AUTOMATED_TESTING'}) ? {} : {'bin/create_db.PL' => 'bin/create_db'}),
	# PPM_INSTALL_EXEC	=> 'bash',
	# PPM_INSTALL_SCRIPT	=> 'bin/create_sqlite',
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
