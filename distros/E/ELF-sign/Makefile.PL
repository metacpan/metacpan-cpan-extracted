use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ELF::sign',
    AUTHOR              => 'Markus Schraeder <privi@cpan.org>',
    VERSION_FROM        => 'lib/ELF/sign.pm',
    ABSTRACT_FROM       => 'lib/ELF/sign.pm',
    PL_FILES            => {},
    LIBS		=> ['-ldl -lssl'],
    #TYPEMAPS		=> ['./typemap'],
    PREREQ_PM => {
        'Test::More' => 0,
        'Net::SSLeay'   => '1.65',
        'XSLoader'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ELF-sign-*' },
);
