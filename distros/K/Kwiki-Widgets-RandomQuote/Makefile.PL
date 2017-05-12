use inc::Module::Install;

name            ('Kwiki-Widgets-RandomQuote');
abstract        ('Quote a random paragraph from wiki pages.');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Widgets/RandomQuote.pm');
requires        ('Kwiki');
build_requires  ('Test::More');

&WriteAll;

