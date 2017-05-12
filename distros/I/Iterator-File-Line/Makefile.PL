use strict;
use inc::Module::Install;

name('Iterator-File-Line');
all_from('lib/Iterator/File/Line.pm');
requires('Class::Accessor::Fast');
requires('PerlIO::eol');
requires('PerlIO::encoding');

build_requires('Encode');
build_requires('utf8');

auto_install;
WriteAll;