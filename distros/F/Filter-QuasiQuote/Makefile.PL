use strict;
use lib '.';
use inc::Module::Install;

name                ('Filter-QuasiQuote');
license             ('MIT');
author              ('Agent Zhang <agentzh@yahoo.cn>');
perl_version        ('5.006001');
all_from            ('lib/Filter/QuasiQuote.pm');

requires            ('Filter::Util::Call' => '1.07');

build_requires      ('Test::More');

auto_install();
WriteAll();

