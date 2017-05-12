use strict;
#use warnings;  # I like to be able to say that this is perl5.2-compatible
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::EL::Poly2Mono',
    AUTHOR              => 'Father Chrysostomos',
    VERSION_FROM        => 'lib/Lingua/EL/Poly2Mono.pm',
    ABSTRACT_FROM       => 'lib/Lingua/EL/Poly2Mono.pm',
    PL_FILES            => {},
#    PREREQ_PM => {
#        'Test::More' => 0,
#    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-EL-Poly2Mono-*' },
);
