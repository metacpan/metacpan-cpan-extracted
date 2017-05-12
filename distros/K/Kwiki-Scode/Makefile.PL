use inc::Module::Install;

name            ('Kwiki-Scode');
abstract        ('Scode plugin saves you from wiki spammers');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Scode.pm');
requires        ('Kwiki' => 0.36);
requires        ('GD');
build_requires  ('Test::More');

&WriteAll;

