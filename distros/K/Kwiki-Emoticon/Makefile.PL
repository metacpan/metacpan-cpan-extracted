use inc::Module::Install;

name            ('Kwiki-Emoticon');
abstract        ('');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Emoticon.pm');
requires        ('Spiffy');
requires        ('Text::Emoticon', 0.03);
build_requires  ('Test::More');

&WriteAll;

