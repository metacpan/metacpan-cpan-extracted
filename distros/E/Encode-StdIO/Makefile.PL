use strict;
use inc::Module::Install;

name('Encode-StdIO');
all_from('lib/Encode/StdIO.pm');

recommends('Term::Encoding');
build_requires('Test::More');

auto_include;
WriteAll;