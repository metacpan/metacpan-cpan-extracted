use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FreeMED::Relay',
    AUTHOR              => 'Jeff Buchbinder <RTFIREFLY@cpan.org>',
    VERSION_FROM        => 'lib/FreeMED/Relay.pm',
    ABSTRACT_FROM       => 'lib/FreeMED/Relay.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FreeMED-Relay-*' },
);
