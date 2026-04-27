use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    NAME             => 'Heap::PQ',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Heap/PQ.pm',
    ABSTRACT_FROM    => 'lib/Heap/PQ.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.010',
    macro            => { TARFLAGS   => "--format=ustar -c -v -f" },
    OBJECT           => 'HeapPQ$(OBJ_EXT)',
    C                => ['HeapPQ.c'],
    XS               => {},
    INC              => '-Iinclude',
    INST_LIB         => 'blib/lib',
    INST_ARCHLIB     => 'blib/arch',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Heap-PQ-* xs/HeapPQ/*.o xs/HeapPQ/*.bs' },
);
