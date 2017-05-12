
use inc::Module::Install;

name            ('Kwiki-LiveSearch');
abstract        ('Search and Display the page link on the fly!');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/Kwiki/LiveSearch.pm');
requires        ('Kwiki' => 0.38);

&WriteAll;

