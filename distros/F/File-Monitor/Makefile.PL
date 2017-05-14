use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME                => 'File::Monitor',
    AUTHOR              => 'Andy Armstrong <andy@hexten.net>',
    VERSION_FROM        => 'lib/File/Monitor.pm',
    ABSTRACT_FROM       => 'lib/File/Monitor.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Monitor-*' },
);
