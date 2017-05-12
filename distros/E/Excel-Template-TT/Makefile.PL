use strict;
use inc::Module::Install;

name('Excel-Template-TT');
all_from('lib/Excel/Template/TT.pm');

requires('File::Temp');
requires('Template');
requires('Excel::Template');
build_requires('Test::More');

auto_install;
WriteAll;
