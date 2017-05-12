use inc::Module::Install;

name            ('Kwiki-Widgets-RecentChanges');
abstract        ('Widget version of RecentChanges');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Widgets/RecentChanges.pm');
requires        ('Kwiki');
build_requires  ('Test::More');

&WriteAll;

