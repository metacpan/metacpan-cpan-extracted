use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Launcher::Cascade',
    AUTHOR              => 'Cédric Bouvier <cbouvi@cpan.org>',
    VERSION_FROM        => 'lib/Launcher/Cascade.pm',
    ABSTRACT_FROM       => 'lib/Launcher/Cascade.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Log::Log4perl' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Launcher-Cascade-*' },
);
