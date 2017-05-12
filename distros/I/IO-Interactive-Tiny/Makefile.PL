use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IO::Interactive::Tiny',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/IO/Interactive/Tiny.pm',
    ABSTRACT_FROM       => 'lib/IO/Interactive/Tiny.pod',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0, # for testing, I know I know: Test::XT
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IO-Interactive-Tiny-*' },
);
