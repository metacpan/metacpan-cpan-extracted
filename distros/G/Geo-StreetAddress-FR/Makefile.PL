use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Geo::StreetAddress::FR',
    AUTHOR        => 'franck cuny <franck.cuny@gmail.com>',
    VERSION_FROM  => 'lib/Geo/StreetAddress/FR.pm',
    LICENSE       => 'perl',
    ABSTRACT_FROM => 'lib/Geo/StreetAddress/FR.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'         => 0,
        'version'            => 0,
        'Test::Perl::Critic' => 0,
        'Class::Accessor::Fast' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Geo-StreetAddress-FR-*' },
);
