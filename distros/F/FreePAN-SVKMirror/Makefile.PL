use inc::Module::Install;

name            ('FreePAN-SVKMirror');
abstract        ('FreePAN SVKMirror Plugin');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/FreePAN/SVKMirror.pm');
requires        (FreePAN => 0, SVK => '0.30');
build_requires  ('Test::More');

&WriteAll;

