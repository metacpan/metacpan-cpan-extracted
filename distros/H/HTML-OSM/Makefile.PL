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
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	NAME => 'HTML::OSM',
	VERSION_FROM => 'lib/HTML/OSM.pm', # finds $VERSION in the module
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'gpl_2')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, META_MERGE => {
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
	}, PREREQ_PM => {
		'Carp' => 0,
		'CHI' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'LWP::UserAgent' => 0,
		'JSON::MaybeXS' => 0,
		'Object::Configure' => 0.15,
		'Params::Get' => 0.13,
		'Params::Validate::Strict' => 0.28,
		'Readonly' => 0,
		'Scalar::Util' => 0,
		'Time::HiRes' => 0,
		'URI::Escape' => 0
	}, TEST_REQUIRES => {
		'File::Temp' => 0,
		'IPC::System::Simple' => 0,
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::HTML::Lint' => 0,
		'Test::HTTPStatus' => 0,
		'Test::JSON' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::RequiresInternet' => 0,
		'Test::Returns' => 0,
		'Test::Warnings' => 0,
		'Test::Which' => 0,
		'Test::Without::Module' => 0
	}, dist => $dist,
	clean => { FILES => 'HTML-OSM-*' },	# Clean up distribution files
);
