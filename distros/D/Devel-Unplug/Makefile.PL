use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Devel::Unplug',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Devel/Unplug.pm',
    ABSTRACT_FROM => 'lib/Devel/Unplug.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'             => 0,
        'Devel::TraceLoad::Hook' => '1.0.1',
        'File::Spec'             => 0,
        'IPC::Run'               => '0.80',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Devel-Unplug-*' },
);
