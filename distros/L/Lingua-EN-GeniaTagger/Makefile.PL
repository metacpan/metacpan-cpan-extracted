use inc::Module::Install;

name            ('Lingua-EN-GeniaTagger');
abstract        ('GENIA Tagger');
author          ('Yung-chung Lin <xern@cpan.org>');
version_from    ('lib/Lingua/EN/GeniaTagger.pm');
license         ('perl');

build_requires  ('Test::More');

auto_install();

&WriteAll;

