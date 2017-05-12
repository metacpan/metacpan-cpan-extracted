use inc::Module::Install;

name            ('Kwiki-CachedDisplay');
abstract        ('Speed-up Kwiki page display by caching');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/CachedDisplay.pm');
requires        ('Kwiki' => '0.37');
build_requires  ('Test::More');

&WriteAll;

