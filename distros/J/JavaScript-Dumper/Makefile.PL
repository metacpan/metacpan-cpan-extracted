use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'JavaScript::Dumper',
    AUTHOR              => 'Moritz Onken <onken@houseofdesign.de>',
    VERSION_FROM        => 'lib/JavaScript/Dumper.pm',
    ABSTRACT_FROM       => 'lib/JavaScript/Dumper.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'JSON::PP' => 2.14,
	'Class::C3' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'JavaScript-Dumper-*' },
);
