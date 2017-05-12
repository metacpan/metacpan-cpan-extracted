use inc::Module::Install;

name            ('Lingua-POSAlign');
abstract        ('POS tag alignment tool for texts');
author          ('Yung-chung Lin <xern@cpan.org>');
version_from    ('lib/Lingua/POSAlign.pm');
license         ('perl');

build_requires  ('Test::More');
auto_install();

&WriteAll;

