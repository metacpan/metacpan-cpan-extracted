use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Inline::Basic',
    'VERSION_FROM' => 'lib/Inline/Basic.pm', # finds $VERSION
    'PREREQ_PM' => {
	Inline => 0.43,
	Language::Basic => 1.44,
	IO::Scalar => 2.104,
    },
);
