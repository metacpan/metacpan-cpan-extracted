use inc::Module::Install;

name            ('Kwiki-DB');
abstract        ('DBI access for Kwiki plugin writers');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version         ('0.02');
requires        (
    'Kwiki' => 0.38,
    DBI => 0
    );
build_requires  ('Test::More' => 0, 'DBD::SQLite' => 0);

&WriteAll;

