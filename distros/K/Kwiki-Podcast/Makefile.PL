use inc::Module::Install;

name            ('Kwiki-Podcast');
abstract        ('Podcasting in a Kwiki way');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Podcast.pm');
requires        ('Kwiki');
build_requires  ('Test::More');

&WriteAll;

