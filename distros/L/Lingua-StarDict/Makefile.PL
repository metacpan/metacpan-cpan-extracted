use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::StarDict',
    VERSION_FROM      => 'lib/Lingua/StarDict.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Lingua/StarDict.pm', 
       AUTHOR         => 'Vadim Suhanov <suhanov_vadim@mail.ru>') : ()),

    CC                => 'g++',
    LD                => '$(CC)',
    XSOPT             => '-C++',

    TYPEMAPS          => ['typemap'],
    LIBS              => ['-lstdc++ -lglib-2.0 -lz -lstardict'], 
    DEFINE            => '',
    INC               => '-I. -I./sd/. -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include', 

);
