use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME' => 'IO::Tee',
    'VERSION_FROM' => 'Tee.pm',
    'dist' => { COMPRESS => 'gzip -9f',
                SUFFIX => '.gz',
                DIST_DEFAULT => 'all tardist' },
);
