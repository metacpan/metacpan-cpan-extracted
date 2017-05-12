
use 5.008002;
use ExtUtils::MakeMaker;

my @mm;

if (eval $ExtUtils::MakeMaker::VERSION >= 6) {
    push @mm, AUTHOR        => 'Alexandr Gomoliako <zzz@zzz.org.ua>',
              ABSTRACT_FROM => 'lib/HTTP/Parser2/XS.pm';
}

if (eval $ExtUtils::MakeMaker::VERSION >= 6.30_01) {
    push @mm, LICENSE => 'perl';
}

WriteMakefile(
    dist         => {
        PREOP      => 'pod2text lib/HTTP/Parser2/XS.pm '.
                        '| tee README >$(DISTVNAME)/README; '.
                      'chmod -R u=rwX,go=rX . ;',
        COMPRESS   => 'gzip -9v',
        SUFFIX     => '.gz',
    },
    NAME         => 'HTTP::Parser2::XS',
    VERSION_FROM => 'lib/HTTP/Parser2/XS.pm',
    PREREQ_PM    => {
        'Test::More' => 0,
    },
    INC          => '-I.', 
    DEFINE       => '', 
    OBJECT       => '$(O_FILES)', 
    @mm
);

