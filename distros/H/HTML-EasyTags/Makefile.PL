use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'HTML::EasyTags',
	VERSION_FROM => 'lib/HTML/EasyTags.pm', # finds $VERSION
	PREREQ_PM => {
	},
);
