
use inc::Module::Install;

name            ('Kwiki-Outline2Html');
abstract        ('Kwiki Formatter using outline2html syntax');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/Kwiki/Outline2HTML.pm');
requires        ('Kwiki' => '0.31');

&WriteAll;

