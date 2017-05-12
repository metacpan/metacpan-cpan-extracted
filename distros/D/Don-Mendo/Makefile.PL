use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Don::Mendo',
    AUTHOR              => 'JJ Merelo <jj@merelo.net>',
    VERSION_FROM        => 'lib/Don/Mendo.pm',
    ABSTRACT_FROM       => 'lib/Don/Mendo.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Carp' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Don-Mendo-*' },
);
