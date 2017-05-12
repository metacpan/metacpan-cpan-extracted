use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Integer::Tiny',
    AUTHOR              => 'Pawel bbkr Pabian <cpan@bbkr.org>',
    VERSION_FROM        => 'lib/Integer/Tiny.pm',
    ABSTRACT_FROM       => 'lib/Integer/Tiny.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'Math::BigInt' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Integer-Tiny-*' },
);
