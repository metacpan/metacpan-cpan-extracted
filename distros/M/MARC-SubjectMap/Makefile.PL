use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME          => 'MARC::SubjectMap',
    DISTNAME      => 'MARC-SubjectMap',
    VERSION_FROM  => 'lib/MARC/SubjectMap.pm',
    ABSTRACT_FROM => 'lib/MARC/SubjectMap.pm',
    AUTHOR        => 'Ed Summers <ehs@pobox.com>',
    PREREQ_PM     => {
                        'Test::More'        => 0,
                        'Test::Exception'   => 0,
                        'MARC::Record'      => 0,
                        'Class::Accessor'   => 0,
                        'XML::SAX'          => 0,
                        'BerkeleyDB'        => 0,
                        'Storable'          => 0,
                     },
    EXE_FILES     => [ qw( bin/subjmap bin/subjmap-template ) ],
);
