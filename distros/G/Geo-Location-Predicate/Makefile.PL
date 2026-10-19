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
	NAME => 'Geo::Location::Predicate',
	VERSION_FROM => 'lib/Geo/Location/Predicate.pm',
	ABSTRACT_FROM => 'lib/Geo/Location/Predicate.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	LICENSE => 'gpl_2',	# The LICENSE file is GPL v2; 'GPL' is written to META as 'open_source'
	# use Exporter qw(import) needs Exporter 5.57, first shipped with 5.8.3
	MIN_PERL_VERSION => '5.008003',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '6.64',	# First to understand TEST_REQUIRES
	},
	# The rule needs nothing but perl: it is one sub with one pattern, which is
	# why it is a distribution of its own rather than a reason to install the
	# facade and its databases.
	PREREQ_PM => {},
	TEST_REQUIRES => {
		'Errno' => 0,
		'POSIX' => 0,
		'Scalar::Util' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	},
	dist => $dist,
	clean => { FILES => 'Geo-Location-Predicate-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Geo::Location::Predicate',
			repository => {
				repository => 'https://github.com/nigelhorne/Geo-Location-Predicate',
				type => 'git',
				url => 'git://github.com/nigelhorne/Geo-Location-Predicate.git',
				web => 'https://github.com/nigelhorne/Geo-Location-Predicate',
			}, bugtracker => {
				mailto => 'bug-Geo-Location-Predicate@rt.cpan.org',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Location-Predicate',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Location-Predicate',
			}
		},
	},
);
