use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::Diff',
    AUTHOR              => 'Ian Langworth <ian@cpan.org>',
    VERSION_FROM        => 'lib/Kwiki/Diff.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/Diff.pm',
    PREREQ_PM => {qw(
        Test::More 0
        Spiffy 0.22
        Kwiki 0.34
        Kwiki::Revisions 0.12
        Algorithm::Diff 1.18
    )},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-Diff-*' },
);
