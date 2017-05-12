use strict;
use lib '.';
use inc::Module::Install;

name            ('Makefile-GraphViz');
perl_version    ('5.006001');
all_from        ('lib/Makefile/GraphViz.pm');

repository      ("https://github.com/agentzh/makefile-graphviz-pm");

install_script  ("script/gvmake");

requires        ('GraphViz' => '2.16');
requires        ('Makefile::Parser' => '0.216');

build_requires  ('Test::More');
build_requires  ('File::Compare');

no_index        (
    directory =>
        qw< samples >
);

auto_install;
WriteAll;

