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
	NAME           => 'Geo::Address::Parser::Country',
	AUTHOR         => 'Nigel Horne <njh@nigelhorne.com>',
	VERSION_FROM   => 'lib/Geo/Address/Parser/Country.pm',
	ABSTRACT_FROM  => 'lib/Geo/Address/Parser/Country.pm',
	LICENSE        => 'gpl_2',
	MIN_PERL_VERSION => '5.010',
	PREREQ_PM => {
		'Carp'                   => 0,
		'Locale::AU'             => 0,
		'Locale::CA'             => 0,
		'Locale::Object::Country' => 0,
		'Locale::US'             => 0,
		'Object::Configure' => 0,
		'Params::Get'            => 0.13,
		'Params::Validate::Strict' => 0.10,
		'Return::Set'            => 0,
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Geo::Address::Parser::Country',
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Geo-Address-Parser-Country.git',
				web => 'https://github.com/nigelhorne/Geo-Address-Parser-Country',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Address-Parser-Country',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Address-Parser-Country',
				# web => 'https://github.com/nigelhorne/Geo-Address-Parser-Country/issues',
				# url => 'https://github.com/nigelhorne/Geo-Address-Parser-Country/issues',
				mailto => 'bug-Geo-Address-Parser-Country@rt.cpan.org'
			}
		},
	},
	dist => $dist,
	clean => { FILES  => 'Geo-Address-Parser-Country-*' },
);
