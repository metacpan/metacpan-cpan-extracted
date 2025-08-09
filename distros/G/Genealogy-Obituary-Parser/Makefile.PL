use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f', # Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME         => 'Genealogy::Obituary::Parser',
	ABSTRACT_FROM	=> 'lib/Genealogy/Obituary/Parser.pm',
	VERSION_FROM => 'lib/Genealogy/Obituary/Parser.pm',
	AUTHOR	=> 'Nigel Horne <njh@nigelhorne.com>', # Author information
	LICENSE      => 'GPL',
	PREREQ_PM    => {
		'DateTime::Format::Text' => 0,
		'Geo::Coder::Free' => 0,
		'Geo::Coder::List' => 0
	}, TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0
	}, dist => $dist,
	clean	 => {
		FILES => 'Genealogy-Obituary-Parser-*',
	}
);
