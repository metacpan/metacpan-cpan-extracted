# $Id: Makefile.PL 10 1998-12-16 23:02:45Z daniel $

use inc::Module::Install;

name('MP3-Info');
license('perl');
perl_version('5.004');
all_from('Info.pm');

build_depends('Test::More');

auto_install();
WriteAll();
