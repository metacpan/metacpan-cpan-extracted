use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::StarDict::Gen',
    AUTHOR              => 'J.Joao <jjoao@cpan.org>',
    VERSION_FROM        => 'lib/Lingua/StarDict/Gen.pm',
    EXE_FILES           => [ "example/thesaurus2stardict",
                             "example/term2stardict"],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Encode' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lingua-StarDict-Gen-*' },
);
