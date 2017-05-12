use strict;
use inc::Module::Install;

name('Encode-Argv');
all_from('lib/Encode/Argv.pm');

requires('Encode');
recommends('Term::Encoding');
build_requires('Test::More');

auto_include;
WriteAll;