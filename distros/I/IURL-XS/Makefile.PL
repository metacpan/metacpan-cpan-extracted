use 5.024000;
use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    NAME              => 'IURL::XS',
    ABSTRACT_FROM     => 'lib/IURL/XS.pm',
    VERSION_FROM      => 'lib/IURL/XS.pm',
    MIN_PERL_VERSION  => '5.24.0',
    PREREQ_PM         => {'XSLoader' => 0,},
    AUTHOR            => 'Peter P. Neuromantic <p.brovchenko@protonmail.com>',
    LICENSE           => 'mit',
    LIBS              => '',
    DEFINE            => '',
    INC               => '-Isrc',
    OBJECT            => '$(O_FILES)',
    CCFLAGS           => ( $Config{ccflags} // '' ) . ' -Wall -Wextra -std=c11',
    OPTIMIZE          => '-O3 -march=native',
    META_MERGE        => {
        'meta-spec' => {
            version => 2
        },
        resources   => {
            bugtracker => {
                web => 'https://github.com/ChaoticEvil/p5-iurl-xs/issues'
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/ChaoticEvil/p5-iurl-xs.git',
                web  => 'https://github.com/ChaoticEvil/p5-iurl-xs',
            },
        },
    },
);
