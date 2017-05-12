
use inc::Module::Install;

name            ('Kwiki-Infobox');
abstract        ('slash-like infobox for kwiki');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/Kwiki/Infobox.pm');
requires        (Kwiki => '0.38');

&WriteAll;

