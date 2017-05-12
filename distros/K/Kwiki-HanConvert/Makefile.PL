use inc::Module::Install;

name            ('Kwiki-HanConvert');
abstract        ('Trad./Simp. Chinese convertor');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/HanConvert.pm');
requires        ('Kwiki' => 0.36);
requires        ('Encode::HanConvert');
build_requires  ('Test::More');

&WriteAll;

