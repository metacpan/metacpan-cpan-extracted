use inc::Module::Install;

name            ('Kwiki-Session');
abstract        ('Session support in your Kwiki plugin.');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Session.pm');
requires        ('Kwiki' => 0.38);
build_requires  ('Test::More');

&WriteAll;

