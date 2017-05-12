use 5.008004;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT_FROM => 'lib/Disque.pm',
    NAME          => 'Disque',
    AUTHOR        => 'Ezequiel Lovelle <ezequiellovelle@gmail.com>',
    VERSION_FROM  => 'lib/Disque.pm',
    ABSTRACT_FROM => 'lib/Disque.pm',
    LICENSE       => 'MIT',
    PREREQ_PM     => {
        'Redis'      => 1.97,
        'List::Util' => 0,
        'Carp'       => 0,
        'Encode'     => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.3002,
    },
    BUILD_REQUIRES => {
        'Test::More'         => 0.96,
        'Test::TCP'          => 1.17,
        'Digest::SHA'        => 0,
    },
    META_MERGE => {
        requires  => { perl => 5.008004, },
        resources => {
            homepage   => 'https://github.com/lovelle/perl-disque',
            bugtracker => 'https://github.com/lovelle/perl-disque/issues',
            repository => 'git://github.com/lovelle/perl-disque',
            license    => 'https://github.com/lovelle/perl-disque/blob/master/LICENSE',
        },
        keywords       => ['disque'],
    },
);
