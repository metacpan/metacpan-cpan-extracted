use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details on how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'HTML::FormEngine::DBSQL',
	VERSION_FROM => 'DBSQL.pm', # finds $VERSION
	PREREQ_PM => {
		'Hash::Merge' => 0.07,
		'Locale::gettext' => 1.01,
		'Digest::MD5' => 2.24,
		'Clone' => 0.13,
		'DBI' => 1.42,
		'HTML::FormEngine' => 1.0
	},
);
