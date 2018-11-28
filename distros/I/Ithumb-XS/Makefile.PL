use 5.020001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Ithumb::XS',
    VERSION_FROM      => 'lib/Ithumb/XS.pm',
    MIN_PERL_VERSION  => '5.20.1',
    PREREQ_PM         => {'XSLoader' => 0,},
    ABSTRACT_FROM     => 'lib/Ithumb/XS.pm',
    AUTHOR            => 'Peter P. Neuromantic <p.brovchenko@protonmail.com>',
    LICENSE           => 'perl',
    LIBS              => ['-L/usr/lib64 -lImlib2'],
    DEFINE            => '',
    INC               => '-I/usr/include',
);
