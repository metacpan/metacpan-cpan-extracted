use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'       => 'GMail::Checker',
    'VERSION_FROM' => 'Checker.pm',
    'PREREQ_PM'      => {
                    'IO::Socket::SSL'     => 0,
	         },
);
