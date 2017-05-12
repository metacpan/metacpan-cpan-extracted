use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::TypoGenerator',
    'VERSION_FROM'	=> 'lib/Lingua/TypoGenerator.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Test::Simple' => 0,
    },
);
