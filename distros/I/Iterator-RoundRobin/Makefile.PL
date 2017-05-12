use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Iterator::RoundRobin',
    AUTHOR              => 'Nick Gerakines <nick@gerakines.net>',
    VERSION_FROM        => 'lib/Iterator/RoundRobin.pm',
    ABSTRACT_FROM       => 'lib/Iterator/RoundRobin.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'English' => 0,
        'overload' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Iterator-RoundRobin-*' },
);
