use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f', # Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME => 'HTML::D3',
	VERSION_FROM => 'lib/HTML/D3.pm', # finds $VERSION in the module
	AUTHOR => 'Nigel Horne <njh@bandsman.co.uk>',
	ABSTRACT => 'A simple Perl module for generating bar charts using D3.js',
	LICENSE => 'perl',
	META_MERGE => {
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/d3-chart.git',
				web => 'https://github.com/nigelhorne/d3-chart',
			},
			bugtracker => {
				web => 'https://github.com/nigelhorne/d3-chart/issues',
			},
		},
	},
	PREREQ_PM => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'JSON::MaybeXS' => 0,	# Required for encoding data to JSON
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::HTML::T5' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0
	}, dist => $dist,
	clean	 => {
		FILES => 'HTML-D3-*',
	},
);
