use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME	 => 'Geo::AnomalyDetector',
	VERSION_FROM => 'lib/Geo/AnomalyDetector.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	ABSTRACT => 'Detect anomalies in geospatial coordinate datasets',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM => {
		'ExtUtils::MakeMaker' => 6.64,
		'Statistics::Basic' => 0,
		'Math::Trig' => 0,
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,
	},
	TEST_REQUIRES => {
		'Geo::Location::Point' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	}, dist => $dist, clean => {
		FILES => 'Geo-AnomalyDetector-*'
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				repository => 'https://github.com/nigelhorne/Geo-AnomalyDetector',
				type => 'git',
				url => 'git://github.com/nigelhorne/Geo-AnomalyDetector.git',
				web => 'https://github.com/nigelhorne/Geo-AnomalyDetector'
			}, bugtracker => {
				mailto => 'bug-Geo-AnomalyDetector@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Geo-AnomalyDetector/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-AnomalyDetector',
				web => 'https://github.com/nigelhorne/Geo-AnomalyDetector/issues'
			}
		},
	},
	MIN_PERL_VERSION => '5.008'
);
