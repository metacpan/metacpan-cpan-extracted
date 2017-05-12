use inc::Module::Install;

name            ('Kwiki-PageInclude');
abstract        ('Include other page into this one.');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/PageInclude.pm');
requires        ('Spiffy');
build_requires  ('Test::More');

&WriteAll;

