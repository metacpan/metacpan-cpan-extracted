use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'HTML::FormEngine',
	VERSION_FROM => 'FormEngine.pm', # finds $VERSION
	PREREQ_PM => {
		'Clone' => 0.13,
		'Hash::Merge' => 0.07,
		'Locale::gettext' => 1.01,
		'Date::Pcalc' => 1.2,
		'Digest::MD5' => 2.24,
		'HTML::Entities' => 1.27,
	},
);
