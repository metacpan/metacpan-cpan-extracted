# File : Makefile.PL
use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use Config;
WriteMakefile(
    NAME      => "Mac::Launcher",     # Name of package
    LIBS      => [],                  # Name of custom libraries
    LDDLFLAGS => $Config{lddlflags}
      . " -framework CoreFoundation -framework Carbon"
    ,                                 #Link Core Foundation framework
    OBJECT   => "launcher.o launcher_wrap.o",           # Object files
    AUTHOR => q{Kevin Walzer <kw@codebykevin.com>},
    LICENSE => 'MIT',
    dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Mac-Launcher-*' },
    VERSION_FROM  => 'Launcher.pm',
    ABSTRACT_FROM => 'Launcher.pm',
);

