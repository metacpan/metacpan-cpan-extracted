use inc::Module::Install;

name            ('Locale-Memories');
abstract        ("L10N Message Retrieval");
author          ('Yung-chung Lin <henearkrxern@gmail.org>');
version_from    ('lib/Locale/Memories.pm');
license         ('perl');

requires('File::Find::Rule');
requires('Locale::PO');
requires('Search::Xapian');
requires('String::Similarity');

build_requires('Test::More');
install_script('bin/pomagic');
install_script('bin/pofetcher');
install_script('bin/msgtranslator');
auto_install();

&WriteAll;

