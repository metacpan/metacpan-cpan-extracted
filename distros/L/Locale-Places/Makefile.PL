#!/usr/bin/env perl

# FIXME: we shouldn't be downloading in the Makefile - move that to a script

use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use IO::Socket::INET;

my $site = 'download.geonames.org';

# Test for broken smokers that don't set AUTOMATED_TESTING
if(my $reporter = $ENV{'PERL_CPAN_REPORTER_CONFIG'}) {
	if($reporter =~ /smoker/i) {
		warn 'AUTOMATED_TESTING added for you';
		$ENV{'AUTOMATED_TESTING'} = 1;
	}
}

if(!IO::Socket::INET->new(PeerAddr => "$site:80", Timeout => 5)) {
	print STDERR "NA: Can't connect to $site\n";
	exit(0);
}

if(defined($ENV{'GITHUB_ACTION'}) || defined($ENV{'TRAVIS_PERL_VERSION'}) || defined($ENV{'APPVEYOR'})) {
	# Prevent downloading and installing stuff
	$ENV{'AUTOMATED_TESTING'} = 1;
}

my @countries = ($ENV{'AUTOMATED_TESTING'} || $ENV{'NO_NETWORK_TESTING'}) ? () : ('GB', 'US');
my $build_requires = {};
my $test_requires = {
	'Test::Carp' => 0,
	'Test::Most' => 0,
	'Test::Needs' => 0
};

if(scalar(@countries)) {
	$build_requires = {	# For bin/create_sqlite
		'DBI' => 0,
		'File::Copy' => 0,
	};
	$test_requires->{'autodie'} = 0;

	my @dirs = (
		'lib/Locale/Places/data',
	);

	foreach my $dir(@dirs) {
		if(! -d $dir) {
			print "Creating the download directory $dir\n";
			mkdir $dir || die "$dir: $@";
		}
	}

	eval { require 'autodie' };

	# unlink('lib/Locale/Places/data/GB.sql');
	if(eval { require HTTP::Cache::Transparent }) {
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

	foreach my $country(@countries) {
		my $url = "https://$site/export/dump/alternatenames/$country.zip";
		my $file = "lib/Locale/Places/data/$country.zip";

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
			unlink $file;	# Don't leave anything stale around
		}

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

		if(!(-r "lib/Locale/Places/data/$country.csv")) {
			my $zip = "lib/Locale/Places/data/$country.zip";

			print "Exploding $zip\n";

			# Try inline as the external program fails on Windows
			# http://www.cpantesters.org/cpan/report/a03259ca-6c02-1014-bd5e-9b11492b42cd
			eval 'require IO::Uncompress::Unzip';
			if($@) {
				system("unzip $zip") or die "unzip $zip failed";

				rename "$country.txt", "lib/Locale/Places/data/$country.csv" or die "rename: $!";
				unlink 'readme.txt';
			} elsif(open(my $fout, '>', "lib/Locale/Places/data/$country.csv")) {
				IO::Uncompress::Unzip->import();
				if(my $fin = IO::Uncompress::Unzip->new($zip)) {
					do {
						if($fin->getHeaderInfo->{'Name'} eq "$country.txt") {
							while(my $line = $fin->getline()) {
								print $fout $line or die "Error exploding $zip"
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
			# Save disc space, but prevent more than one download
			# if(open(my $fout, '>', $zip)) {
				# close($fout);
			# }
			truncate $zip, 0;
		}

		die if(!(-r "lib/Locale/Places/data/$country.csv"));
	}

	# my $pm = {
		# 'lib/Locale/Places.pm' => 'blib/lib/Locale/Places.pm',
		# 'lib/Locale/Places/DB.pm' => 'blib/lib/Locale/Places/DB.pm',
		# 'lib/Locale/Places/DB/GB.pm' => 'blib/lib/Locale/Places/DB/GB.pm',
	# };

	# if($ENV{'AUTOMATED_TESTING'}) {
		# $pm->{'lib/Locale/Places/data/GB.csv'} = 'blib/lib/Locale/Places/data/GB.csv';
	# } else {
		# $pm->{'lib/Locale/Places/data/GB.sql'} = 'blib/lib/Locale/Places/data/GB.sql';
	# }

	if($Config{'osname'} ne 'MSWin32') {
		$build_requires->{'File::Open::NoCache::ReadOnly'} = 0;
		$build_requires->{'IO::AIO'} = 0;
	}
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
	}, TEST_REQUIRES => $test_requires,
	PREREQ_PM => {
		'CHI' => 0,
		'Database::Abstraction' => 0.04,
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
	dist	=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	clean	=> { FILES => 'Locale-Places-*' },
	EXE_FILES	=> [ 'bin/translate' ],
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
