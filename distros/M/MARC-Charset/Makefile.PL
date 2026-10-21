use 5.8.8;
use ExtUtils::MakeMaker;

use strict;
use warnings;

WriteMakefile(
    NAME            => 'MARC::Charset',
    DISTNAME        => 'MARC-Charset',
    VERSION_FROM    => 'lib/MARC/Charset.pm',
    ABSTRACT_FROM   => 'lib/MARC/Charset.pm',
    AUTHOR          => [
                            'Ed Summers <ehs@pobox.com>',
                            'Galen Charlton <gmcharlt@gmail.com>',
                       ],
    LICENSE         => 'perl',
    MIN_PERL_VERSION => '5.008008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES   => {
        'Test::More' => 0,
    },
    META_MERGE      => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/perl4lib/marc-perl',
            repository => {
                type => 'git',
                url  => 'https://github.com/perl4lib/marc-perl.git',
                web  => 'https://github.com/perl4lib/marc-perl/tree/master/marc-charset',
            },
            bugtracker => {
                web => 'https://github.com/perl4lib/marc-perl/issues',
            },
        },
    },
    PMLIBDIRS       => ['lib'],
    PREREQ_PM       => {
                            'XML::SAX'              => 0,
                            'Class::Accessor'       => 0,
                            'Unicode::Normalize'    => 0,
                       },
);
