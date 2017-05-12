use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Filesys::Tree',
    AUTHOR              => 'Jose Castro <cog@cpan.org>',
    VERSION_FROM        => 'lib/Filesys/Tree.pm',
    ABSTRACT_FROM       => 'lib/Filesys/Tree.pm',
    PL_FILES            => {},
    'EXE_FILES'         => ['tree'],
    PREREQ_PM => {
        'Test::More' => 0,
        'File::Basename' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Filesys-Tree-*' },
);
