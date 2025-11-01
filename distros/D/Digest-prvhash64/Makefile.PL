use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Digest::prvhash64',
    VERSION_FROM => 'lib/Digest/prvhash64.pm',
    ABSTRACT     => 'Perl XS wrapper for prvhash64/prvhash64_64m',
    AUTHOR       => 'Scott Baker <bakerscot@cpan.org>',
    LICENSE      => 'perl',
    XS           => { 'prvhash64.xs' => 'prvhash64.c' },
    INC          => $ENV{PRVHASH_INCLUDE} ? "-I$ENV{PRVHASH_INCLUDE}" : '-I.',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0 },
    BUILD_REQUIRES     => { 'Test::More' => 0 },
    PREREQ_PM          => {},
    META_MERGE => {
        resources => {
            repository => 'https://github.com/your/repo',
        },
    },
);
