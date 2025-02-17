use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	ABSTRACT_FROM	=> 'lib/HTML/OSM.pm',
	AUTHOR => 'Nigel Horne <njh@bandsman.co.uk>',
	NAME => 'HTML::OSM',
	VERSION_FROM => 'lib/HTML/OSM.pm', # finds $VERSION in the module
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM => {
		'Carp' => 0,
		'CHI' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'File::Slurp' => 0,
		'LWP::UserAgent' => 0,
		'JSON::MaybeXS' => 0,
		'Scalar::Util' => 0,
		'Time::HiRes' => 0,
	},
	META_MERGE => {
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/HTML-OSM.git',
				web => 'https://github.com/nigelhorne/HTML-OSM',
			},
			bugtracker => {
				web => 'https://github.com/nigelhorne/HTML-OSM/issues',
			},
		},
	},
	TEST_REQUIRES => {
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::HTML::Lint' => 0,
		'Test::JSON' => 0,
		'Test::MockObject' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::RequiresInternet' => 0,
		'Test::Warnings' => 0
	}, dist => $dist,
	clean => { FILES => 'HTML-OSM-*' },	# Clean up distribution files
);
