
use inc::Module::Install;

name            ('Kwiki-Comments');
abstract        ('Post Comments to Kwiki Pages');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/Kwiki/Comments.pm');
requires        ('Kwiki' => 0.36);
requires	('DBD::SQLite');

&WriteAll;

