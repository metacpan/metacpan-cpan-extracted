use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Git::CPAN::Hook',
    AUTHOR        => 'Philippe Bruhat (BooK) <book@cpan.org>',
    VERSION_FROM  => 'lib/Git/CPAN/Hook.pm',
    ABSTRACT_FROM => 'lib/Git/CPAN/Hook.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'      => 0,
        'CPAN'            => 1.84,
        'Git::Repository' => 1.15,
    },
    META_MERGE => {
        resources =>
            { repository => 'http://github.com/book/Git-CPAN-Hook', },
    },
    dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean   => { FILES    => 'Git-CPAN-Hook-*' },
    LICENSE => 'perl',
);
