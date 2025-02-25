use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		 => 'Geo::AnomalyDetector',
	VERSION_FROM => 'lib/Geo/AnomalyDetector.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	ABSTRACT	 => 'Detect anomalies in geospatial coordinate datasets',
	LICENSE => 'perl',
	PREREQ_PM => {
		'Statistics::Basic' => 0,
		# 'Math::Trig'	 => 0,
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,
	},
	TEST_REQUIRES => {
		'Test::Most' => 0,
	}, dist => $dist, clean => {
		FILES => 'Geo-AnomalyDetector-*'
	},
);
