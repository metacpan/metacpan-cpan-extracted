#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

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
	'http://download.geonames.org/export/dump/alternatenames/GB.zip' => 'lib/Locale/Places/databases/GB.zip',
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
		print "Creating the download directory $cachedir\n";
		mkdir $cachedir || die "$cachedir: $@";
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

my $use_withcache;
if(eval { require LWP::Simple::WithCache; }) {
	LWP::Simple::WithCache->import();
	$use_withcache = 1;
} else {
	require LWP::Simple;
	LWP::Simple->import();

	print "Consider installing LWP::Simple::WithCache to reduce downloads\n";
}

foreach my $url(keys %urls) {
	my $file = $urls{$url};
	if(-r $file) {
		# Don't bother downloading if the file is less than a week old
		next if(-M $file < 7);
	}

	print "Downloading $url to $file\n";
	if($use_withcache) {
		if(LWP::Simple::WithCache::is_error(my $rc = LWP::Simple::WithCache::mirror($url, $file))) {
			die "$url: LWP error $rc";
		}
	} else {
		if(LWP::Simple::is_error(my $rc = LWP::Simple::mirror($url, $file))) {
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

WriteMakefile(
	NAME		=> 'Locale::Places',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Locale/Places.pm',
	ABSTRACT_FROM   => 'lib/Locale/Places.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	BUILD_REQUIRES => {
	}, TEST_REQUIRES =>  {
		'Test::Most' => 0,
	}, PREREQ_PM => {
		'CHI' => 0,
		'DBI' => 0,
		'DBD::CSV' => 0,
		'DBD::SQLite' => 0,
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
	},
	# PPM_INSTALL_EXEC	=> 'bash',
	# PPM_INSTALL_SCRIPT	=> 'bin/create_sqlite',
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
