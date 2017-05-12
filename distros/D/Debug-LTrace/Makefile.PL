use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Debug::LTrace',
    AUTHOR        => q{"koorchik" <"koorchik@cpan.org">},
    VERSION_FROM  => 'lib/Debug/LTrace.pm',
    ABSTRACT_FROM => 'lib/Debug/LTrace.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'Data::Dumper'   => 0,
        'Hook::LexWrap'  => 0,
        'Devel::Symdump' => 0,
        'Time::HiRes'    => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Debug-LTrace-*' },
);

