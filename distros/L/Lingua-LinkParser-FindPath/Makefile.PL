use inc::Module::Install;

name            ('Lingua-LinkParser-FindPath');
abstract_from   ('lib/Lingua/LinkParser/FindPath.pm');
version_from    ('lib/Lingua/LinkParser/FindPath.pm');
author          ('Yung-chung Lin <xern@cpan.org>');
license         ('perl');

requires  ('Lingua::LinkParser');

build_requires  ('Test::More');

auto_install();

&WriteAll;
