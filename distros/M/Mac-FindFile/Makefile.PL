# File : Makefile.PL
use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use Config;
WriteMakefile(
    NAME      => "Mac::FindFile",     # Name of package
    LIBS      => [],                  # Name of custom libraries
    LDDLFLAGS => $Config{lddlflags}
      . " -framework CoreFoundation -framework Carbon -framework CoreServices -framework Cocoa"
    ,                                 #Link Core Foundation framework
    OBJECT   => "findfile.o findfile_wrap.o",           # Object files
    AUTHOR => q{Kevin Walzer <kw@codebykevin.com>},
    LICENSE => 'MIT',
    dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Mac-FindFile-*' },
    VERSION_FROM  => 'FindFile.pm',
    ABSTRACT_FROM => 'FindFile.pm',
);

