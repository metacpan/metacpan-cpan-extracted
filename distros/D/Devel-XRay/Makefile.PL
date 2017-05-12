use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::XRay',
    AUTHOR              => 'Jeff Bisbee <jbisbee@cpan.org>',
    VERSION_FROM        => 'lib/Devel/XRay.pm',
    ABSTRACT_FROM       => 'lib/Devel/XRay.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'Carp'           => 0,
        'Filter::Simple' => 0.78,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-XRay-*' },
    LICENSE             => 'perl',
);
