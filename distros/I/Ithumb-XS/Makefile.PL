use 5.024000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Ithumb::XS',
    ABSTRACT_FROM     => 'lib/Ithumb/XS.pm',
    VERSION_FROM      => 'lib/Ithumb/XS.pm',
    MIN_PERL_VERSION  => '5.24.0',
    PREREQ_PM         => {'XSLoader' => 0,},
    AUTHOR            => 'Peter P. Neuromantic <p.brovchenko@protonmail.com>',
    LICENSE           => 'bsd',
    LIBS              => ['-lImlib2'],
    DEFINE            => '',
    INC               => '-I/usr/include -I/usr/X11/include/'
);
