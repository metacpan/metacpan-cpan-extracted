use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Lingua::ZH::Currency::UpperCase',
    'VERSION_FROM' => 'UpperCase.pm', # finds $VERSION
    'DISTNAME'     => 'Lingua-ZH-Currency-UpperCase',
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
);
