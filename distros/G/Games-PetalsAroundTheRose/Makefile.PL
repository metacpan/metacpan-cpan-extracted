use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::PetalsAroundTheRose',
    AUTHOR              => 'Jose Castro <cog@cpan.org>',
    VERSION_FROM        => 'lib/Games/PetalsAroundTheRose.pm',
    ABSTRACT_FROM       => 'lib/Games/PetalsAroundTheRose.pm',
   'EXE_FILES'          => ['petalsaroundtherose'],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-PetalsAroundTheRose-*' },
);
