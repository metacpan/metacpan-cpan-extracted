use inc::Module::Install;

name            ('Kwiki-UserPhoto');
abstract        ('User Photo');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/UserPhoto.pm');
requires        (
    'Kwiki'  => 0.38,
    'Imager' => 0,
);
build_requires  ('Test::More');

&WriteAll;

