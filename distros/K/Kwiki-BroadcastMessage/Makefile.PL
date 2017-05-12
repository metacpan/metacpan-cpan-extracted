use inc::Module::Install;

name            ('Kwiki-BroadcastMessage');
abstract        ('Broadcasting Message on Kwiki site.');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/BroadcastMessage.pm');
requires        (Kwiki => 0.38);
build_requires  ('Test::More');

&WriteAll;

