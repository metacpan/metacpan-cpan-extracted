use inc::Module::Install;

name            ('Kwiki-Widgets-Links');
abstract        ('A widget that display several given links');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Widgets/Links.pm');
requires        ('Kwiki' => 0.38);
build_requires  ('Test::More');

&WriteAll;

