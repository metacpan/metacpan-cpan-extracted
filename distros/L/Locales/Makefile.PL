use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Locales',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Locales.pm',
    ABSTRACT_FROM => 'lib/Locales.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'          => 0,
        'Test::Carp'          => 0,
        'File::Slurp'         => 0,
        'ExtUtils::MakeMaker' => '6.56',
        'Module::Want'        => '0.6',
        'String::UnicodeUTF8' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'   => 0,
        'Test::Carp'   => 0,
        'File::Slurp'  => 0,
        'Module::Want' => '0.6',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.56,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Locales-*' },
);
