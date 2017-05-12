use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::WavingHands',
    AUTHOR              => 'Desmond Daignault <nawglan@cpan.org>',
    VERSION_FROM        => 'lib/Games/WavingHands.pm',
    ABSTRACT_FROM       => 'lib/Games/WavingHands.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games::WavingHands-*' },
);
