use inc::Module::Install;

name            ('Kwiki-Search-Plucene');
abstract        ('Kwiki Search Engine powered by Plucene');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Search/Plucene.pm');
requires        ('Kwiki::Search' => 0.12);
requires        ('Plucene::Simple');
build_requires  ('Test::More');

&WriteAll;

