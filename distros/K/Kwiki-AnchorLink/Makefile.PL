
use inc::Module::Install;

name            ('Kwiki-AnchorLink');
abstract        ('Provide anchor link phrse to Kwiki');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/Kwiki/AnchorLink.pm');
requires        (Kwiki => 0.38);

&WriteAll;

