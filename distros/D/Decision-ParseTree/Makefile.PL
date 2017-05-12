use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Decision::ParseTree',
    AUTHOR              => 'ben hengst <notbenh@cpan.org>',
    VERSION_FROM        => 'lib/Decision/ParseTree.pm',
    ABSTRACT_FROM       => 'lib/Decision/ParseTree.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp::Assert::More' => 0,
        'YAML' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Decision-ParseTree-*' },
);
