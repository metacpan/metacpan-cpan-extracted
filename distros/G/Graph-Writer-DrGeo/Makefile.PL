use inc::Module::Install;

name            ('Graph-Writer-DrGeo');
abstract        ('1');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Graph/Writer/DrGeo.pm');
requires        ('Graph::Writer');
build_requires  ('Test::More');

&WriteAll;

