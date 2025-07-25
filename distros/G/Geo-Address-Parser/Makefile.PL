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
	NAME => 'Geo::Address::Parser',
	VERSION_FROM => 'lib/Geo/Address/Parser.pm', # finds $VERSION
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	ABSTRACT_FROM => 'lib/Geo/Address/Parser.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, EXE_FILES => ['bin/geo-parse'],
	PREREQ_PM => {
		'Carp' => 0,
		'Exporter' => 0,
		'Module::Runtime' => 0,
		'Params::Get' => 0,
		'Text::Capitalize' => 0,
	}, TEST_REQUIRES => {
		'Getopt::Long' => 0,
		'IPC::Open3' => 0,
		'JSON::MaybeXS' => 0,
		'Pod::Usage' => 0,
		'Symbol' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist,
	clean => { FILES => 'Geo-Address-Parser-*' },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Geo::Address::Parser',
			repository => {
				repository => 'https://github.com/nigelhorne/Geo-Address-Parser',
				type => 'git',
				url => 'git://github.com/nigelhorne/Geo-Address-Parser.git',
				web => 'https://github.com/nigelhorne/Geo-Address-Parser',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Geo-Address-Parser@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Geo-Address-Parser/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Address-Parser',
				web => 'https://github.com/nigelhorne/Geo-Address-Parser/issues'
			}
		},
	},
	MIN_PERL_VERSION => '5.14.0'
);
