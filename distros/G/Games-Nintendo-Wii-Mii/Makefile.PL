use strict;
use warnings;

use lib qw(inc);
use inc::Module::Install;

name('Games-Nintendo-Wii-Mii');
author('Toru Yamaguchi <zigorou@cpan.org>');
abstract('Mii in Nintendo Wii data parser and builder');
version_from('lib/Games/Nintendo/Wii/Mii.pm');
license('perl');

requires('Class::Accessor::Fast', 0.30);
requires('Carp', 1.03);
requires('File::Slurp', 9999.12);
requires('IO::File', 1.10);
requires('Readonly'), 1.03;
requires('Tie::IxHash', 1.21);
requires('URI', 1.35);
requires('XML::LibXML', 1.62);

use_test_base;

auto_include;
auto_install;

WriteAll;
