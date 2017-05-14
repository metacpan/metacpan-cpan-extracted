use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Math::MatrixReal::Ext1',
    'VERSION_FROM' => 'Ext1.pm', # finds $VERSION
    PREREQ_PM => {
        'Math::MatrixReal' => 0,
    },
);
