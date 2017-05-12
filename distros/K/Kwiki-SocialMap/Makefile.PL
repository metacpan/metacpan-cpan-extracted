
use inc::Module::Install;

name            ('Kwiki-SocialMap');
abstract        ('Kwiki plugin that render social relations');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/Kwiki/SocialMap.pm');
requires        ('Kwiki' => 0.31);

&WriteAll;

