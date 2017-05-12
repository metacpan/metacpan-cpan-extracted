use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Fukurama::Class',
    AUTHOR              => 'Tobias Tacke <cpan@tobias-tacke.de>',
    VERSION_FROM        => 'lib/Fukurama/Class.pm',
    ABSTRACT_FROM       => 'lib/Fukurama/Class.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::Dumper'	=> 0,
        'Carp'		=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Fukurama-Class-*' },
);
