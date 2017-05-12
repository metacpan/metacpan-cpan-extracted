use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'JavaScript::XRay',
    AUTHOR        => 'Jeff Bisbee <jbisbee@cpan.org>',
    VERSION_FROM  => 'lib/JavaScript/XRay.pm',
    ABSTRACT_FROM => 'lib/JavaScript/XRay.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'            => 0,
        'Carp'                  => 0,
        'LWP::Simple'           => 0,
        'URI'                   => 0,
        'Pod::Usage'            => 0,
        'Getopt::Long'          => 0,
        'File::Spec::Functions' => 0,
        'File::Basename'        => 0,
    },
    EXE_FILES => ['bin/jsxray'],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'JavaScript-XRay-*' },
    LICENSE => 'perl',
);
