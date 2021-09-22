#!/usr/bin/env perl

use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use IO::Socket::INET;

my $site = 'download.geonames.org';

if($ENV{'NO_NETWORK_TESTING'}) {
	print STDERR "NA: NO_NETWORK_TESTING is defined\n";
	exit(0);
}

if(!IO::Socket::INET->new(PeerAddr => "$site:80", Timeout => 5)) {
	print STDERR "NA: Can't connect to $site\n";
	exit(0);
}

my @dirs = (
	'lib/Locale/Places/databases',
);

foreach my $dir(@dirs) {
	if(! -d $dir) {
		print "Creating the download directory $dir\n";
		mkdir $dir || die "$dir: $@";
	}
}

my %urls = (
	"http://$site/export/dump/alternatenames/GB.zip" => 'lib/Locale/Places/databases/GB.zip',
);

# unlink('lib/Geo/Coder/Free/MaxMind/databases/cities.sql');
if(eval { require HTTP::Cache::Transparent; }) {
	HTTP::Cache::Transparent->import();
	my $cachedir;
	if(my $e = $ENV{'CACHEDIR'}) {
		$cachedir = File::Spec->catfile($e, 'http-cache-transparent');
	} else {
		require File::HomeDir;
		File::HomeDir->import();

		# $cachedir = File::Spec->catfile(File::Spec->tmpdir(), 'cache', 'http-cache-transparent');
		$cachedir = File::Spec->catfile(File::HomeDir->my_home(), '.cache', 'http-cache-transparent');
	}

	if(!-d $cachedir) {
		print "Creating the cache directory $cachedir\n";
		mkdir $cachedir || die "$cachedir: $@";
	}
	HTTP::Cache::Transparent::init({
		BasePath => $cachedir,
		# Verbose => $opts{'v'} ? 1 : 0,
		Verbose => 1,
		NoUpdate => 60 * 60 * 24,
		MaxAge => 30 * 24
	}) || die "$0: $cachedir: $!";
} elsif(!$ENV{'AUTOMATED_TESTING'}) {
	print "Consider installing HTTP::Cache::Transparent to reduce downloads\n";
}

my $use_withcache;
if(eval { require LWP::Simple::WithCache; }) {
	LWP::Simple::WithCache->import();
	$use_withcache = 1;
} else {
	require LWP::Simple;
	LWP::Simple->import();

	if(!$ENV{'AUTOMATED_TESTING'}) {
		print "Consider installing LWP::Simple::WithCache to reduce downloads\n";
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

	if($use_mirror) {
		print "Downloading $url to $file if a newer version is available\n";
		if($use_withcache &&
		   LWP::Simple::WithCache::is_error(my $rc = LWP::Simple::WithCache::mirror($url, $file))) {
			die "$url: LWP error $rc";
		} elsif(LWP::Simple::is_error($rc = LWP::Simple::mirror($url, $file))) {
			die "$url: LWP error $rc";
		}
	} else {
		print "Downloading $url to $file\n";
		if($use_withcache &&
		   LWP::Simple::WithCache::is_error(my $rc = LWP::Simple::WithCache::getstore($url, $file))) {
			die "$url: LWP error $rc";
		} elsif(LWP::Simple::is_error($rc = LWP::Simple::getstore($url, $file))) {
			die "$url: LWP error $rc";
		}
	}
	die $file if(!-r $file);
}

if(!(-r 'lib/Locale/Places/databases/GB.csv')) {
	my $zip = 'lib/Locale/Places/databases/GB.zip';
	system("unzip $zip");
	rename 'GB.txt', 'lib/Locale/Places/databases/GB.csv';
	unlink 'readme.txt';
	# Save disc space, but prevent more than one download
	if(open(my $fout, '>', $zip)) {
		close($fout);
	}
}

# my $pm = {
	# 'lib/Locale/Places.pm' => 'blib/lib/Locale/Places.pm',
	# 'lib/Locale/Places/DB.pm' => 'blib/lib/Locale/Places/DB.pm',
	# 'lib/Locale/Places/DB/GB.pm' => 'blib/lib/Locale/Places/DB/GB.pm',
# };

# if($ENV{'AUTOMATED_TESTING'}) {
	# $pm->{'lib/Locale/Places/databases/GB.csv'} = 'blib/lib/Locale/Places/databases/GB.csv';
# } else {
	# $pm->{'lib/Locale/Places/databases/GB.sql'} = 'blib/lib/Locale/Places/databases/GB.sql';
# }

# For bin/create_sqlite
my $build_requires = {
	'DBI' => 0,
	'File::Copy' => 0,
};

if($Config{'osname'} ne 'MSWin32') {
	$build_requires->{'File::Open::NoCache::ReadOnly'} = 0;
	$build_requires->{'IO::AIO'} = 0;
}

WriteMakefile(
	NAME		=> 'Locale::Places',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Locale/Places.pm',
	ABSTRACT_FROM   => 'lib/Locale/Places.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	BUILD_REQUIRES => $build_requires,
	CONFIGURE_REQUIRES => {
		'Config' => 0,
		'File::Which' => 0,
		'LWP::Simple' => 0,
		'Try::Tiny' => 0,
	}, TEST_REQUIRES => {
		'Test::Carp' => 0,
		'Test::Most' => 0,
	}, PREREQ_PM => {
		'CHI' => 0,
		'DBI' => 0,
		'DBD::CSV' => 0,
		'DBD::SQLite' => 0,
		'DBD::SQLite::Constants' => 0,
		'Error::Simple' => 0,
		'File::pfopen' => 0,
		'File::Spec' => 0,
		'Module::Info' => 0,
		'Text::CSV' => 0,
		'Text::xSV::Slurp' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	clean		=> { FILES => 'Locale-Places-*' },
	# META_ADD => {
		# provides => { }
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Locale-Places.git',
				web => 'https://github.com/nigelhorne/Locale-Places',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Locale-Places',
				web => 'https://github.com/nigelhorne/Locale-Places/issues',
				mailto => 'bug-Locale-Places@rt.cpan.org'
			}
		},
	}, PL_FILES => (defined($ENV{'AUTOMATED_TESTING'}) ? {} : {'bin/create_db.PL' => 'bin/create_db'}),
	# , PM => $pm,
	# PPM_INSTALL_EXEC	=> 'bash',
	# PPM_INSTALL_SCRIPT	=> 'bin/create_sqlite',
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
