use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::Stub',
    AUTHOR              => 'Masaki Sawamura <sawamur@cpan.org>',
    VERSION_FROM        => 'lib/Devel/Stub.pm',
    ABSTRACT_FROM       => 'lib/Devel/Stub.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Module::Load' => 0,
	'Sub::Name' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-Stub-*' },
);
