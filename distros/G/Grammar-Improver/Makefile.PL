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
	NAME	 => 'Grammar::Improver',		# Name of the module
	VERSION_FROM => 'lib/Grammar/Improver.pm',	# Automatically fetch version from the module
	AUTHOR	=> 'Nigel Horne <njh@bandsman.co.uk>', # Author information
	ABSTRACT	 => 'A Perl module for improving grammar using an external API.',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	META_MERGE => {
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/Grammar-Improver.git',
				web => 'https://github.com/nigelhorne/Grammar-Improver',
			},
			bugtracker => {
				web => 'https://github.com/nigelhorne/Grammar-Improver/issues',
			},
		},
	},
	PREREQ_PM	=> {						# Dependencies (with versions)
		'Carp' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'LWP::UserAgent' => 0,
		'LWP::Protocol::https' => 0,
		'JSON::MaybeXS'	=> 0
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::RequiresInternet' => 0,
		'Test::Warnings' => 0
	}, dist => $dist,
	clean	 => {
		FILES => 'Grammar-Improver-*',
	}
);
