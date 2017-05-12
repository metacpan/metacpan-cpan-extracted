use inc::Module::Install;

name            ('Kwiki-Template-TT2-UTF8');
abstract        ('UTF8-safe Template');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Template/TT2/UTF8.pm');
requires        ('Kwiki' => 0.36);
build_requires  ('Test::More');

&WriteAll;

