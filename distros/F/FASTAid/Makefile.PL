use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'FASTAid',
    AUTHOR        => 'Jarret Glasscock <glasscock_cpan@mac.com>',
    VERSION_FROM  => 'lib/FASTAid.pm',
    ABSTRACT_FROM => 'lib/FASTAid.pm',
    PREREQ_PM     => {
        'Test::More'      => 0,
        'version'         => 0,
        'Carp'            => 0,
		'Test::Exception' => 0,
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'FASTAid-*' },
);
