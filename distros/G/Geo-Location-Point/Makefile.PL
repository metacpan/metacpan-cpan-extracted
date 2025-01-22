use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
    NAME		=> 'Geo::Location::Point',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/Geo/Location/Point.pm',
    ABSTRACT_FROM       => 'lib/Geo/Location/Point.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
	PREREQ_PM => {
		'Carp' => 0,
		'GIS::Distance' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Scalar::Util' => 0
	}, TEST_REQUIRES => {
		'Test::Carp' => 0,
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		'Test::Needs' => 0,
		'Test::Number::Delta' => 0
	}, dist => $dist,
    clean		=> { FILES => 'Geo-Location-Point-*' },
    META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
	'meta-spec' => { version => 2 },
	resources => {
		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Geo-Location-Point.git',
			web => 'https://github.com/nigelhorne/Geo-Location-Point',
			repository => 'https://github.com/nigelhorne/Geo-Location-Point',
		}, bugtracker => {
			web => 'https://github.com/nigelhorne/Geo-Location-Point/issues',
			url => 'https://github.com/nigelhorne/Geo-Location-Point/issues',
			mailto => 'bug-Geo-Location-Point@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.10.0',
);
