ExtUtils::FakeConfig - allows overriding some %Config values
Config_m             - allows building modules for ActivePerl with MinGW GCC

Mattia Barbon <mbarbon@cpan.org>

INSTALLATION

* UN*X

perl Makefile.PL
make
make install

beware that this module is not very useful on UN*X platforms

* Win32

perl Makefile.PL
# this will output a line -Using: 'MAKE'- where MAKE is either dmake or nmake
MAKE
MAKE install

Please note that the build process will create import libraries for MinGW
and MSVC only if either gcc.exe or cl.exe are on the path while running
Makefile.PL.

MODULES

* ExtUtils::FakeConfig

  This module is meant to be used in module installation,
in case you need an easy way to override some configuration values.
It might be useful for other things, too.

* Config_m

  It is just a front-end to ExtUtils::FakeConfig: it sets up %Config to allow
compilation of ActivePerl modules with MinGW GCC.

Basic use:

perl -MConfig_m Makefile.PL
dmake
dmake test
dmake install

or

set PERL5OPT=-MConfig_m
perl Build.PL
perl Build
perl Build test
perl Build install

  It can be used with CPAN.pm/CPANPLUS.pm, too.

Copyright (c) 2001, 2002, 2004, 2006 Mattia Barbon. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
