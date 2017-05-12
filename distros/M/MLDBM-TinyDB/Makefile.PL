use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> "MLDBM::TinyDB",
	'VERSION_FROM'	=> 'lib/MLDBM/TinyDB.pm', # finds $VERSION
	'AUTHOR'	=> 'Darek Adamkiewicz (d.adamkiewicz@i7.com.pl)',
	'PREREQ_PM'	=> {
			'MLDBM'		=> '0',
			'Storable'	=> '0',
			'Tie::IxHash'	=> '0',
	},
	'SKIP'		=> [qw(static dynamic)],
	'linkext'	=> {LINKTYPE => '' },
);
