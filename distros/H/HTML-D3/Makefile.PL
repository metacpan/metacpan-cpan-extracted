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
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	ABSTRACT => 'A simple Perl module for generating charts using D3.js',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'gpl_2')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,
	}, META_MERGE => {
		prereqs => {
			runtime => {
				recommends => {
					# 'Params::Validate::Strict' => 0,
					'Test::HTML::T5' => 0,
				},
			},
		}, optional_features => {
			html_testing => {
				description => 'Test the HTML output',
				prereqs => {
					runtime => { recommends => { 'Test::HTML::T5' => 0 } }
				},
			},
		}, resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/HTML-D3.git',
				web => 'https://github.com/nigelhorne/HTML-D3',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-D3',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-D3',
				# web => 'https://github.com/nigelhorne/HTML-D3/issues',
				# url => 'https://github.com/nigelhorne/HTML-D3/issues',
				mailto => 'bug-HTML-D3@rt.cpan.org'
			}
		},
	}, PREREQ_PM => {
		'JSON::MaybeXS' => 0,	# Required for encoding data to JSON
		'Object::Configure' => 0.24,
		'Params::Get' => 0,
		'Params::Validate::Strict' => 0.39,
		'Scalar::Util' => 0
	# }, RECOMMENDED => {
		# 'Test::HTML::T5' => 0,
	}, TEST_REQUIRES => {
		'IPC::System::Simple' => 0,
		'Readonly' => 0,
		'Test::DescribeMe' => 0,
		# 'Test::HTML::T5' => 0,	# Removed because of build failures
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0.13,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0,
		'Test::Warnings' => 0,
		'Test::Without::Module' => 0,
	},
	dist => $dist,
	clean => {
		FILES => 'HTML-D3-*',
	},
);
