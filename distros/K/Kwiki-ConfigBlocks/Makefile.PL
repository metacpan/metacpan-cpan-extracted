
use inc::Module::Install;

name            ('Kwiki-ConfigBlocks');
abstract        ('Config kwiki page behavior in the kwiki page');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/Kwiki/ConfigBlocks.pm');
requires        ('Kwiki' => 0.31);

&WriteAll;

