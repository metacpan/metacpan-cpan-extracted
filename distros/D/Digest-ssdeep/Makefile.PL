use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Digest::ssdeep',
    AUTHOR              => 'Reinoso Guzman <reinoso.guzman@gmail.com>',
    VERSION_FROM        => 'lib/Digest/ssdeep.pm',
    ABSTRACT_FROM       => 'lib/Digest/ssdeep.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Text::WagnerFischer' => 0,
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Digest-ssdeep-*' },
);
