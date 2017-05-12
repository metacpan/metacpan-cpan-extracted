use inc::Module::Install;

name            ('Kwiki-Search-Spotlight');
abstract        ('Use Spotlight as Kwiki search engine');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Search/Spotlight.pm');
requires        ('Kwiki' => 0.38);
build_requires  ('Test::More' => 0, 'File::Which' => 0);

&WriteAll;

