use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Amortization',
    AUTHOR              => 'Nathan Wagner <wagner@cpan.org>',
    VERSION_FROM        => 'lib/Finance/Amortization.pm',
    ABSTRACT_FROM       => 'lib/Finance/Amortization.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Amortization-*' },
);
