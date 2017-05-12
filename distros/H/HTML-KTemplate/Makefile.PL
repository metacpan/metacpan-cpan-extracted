use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME' => 'HTML::KTemplate',
	'VERSION_FROM' => 'KTemplate.pm',
	'PREREQ_PM' => {
		'Carp' => 0,
		'File::Spec' => 0,
	},
);
