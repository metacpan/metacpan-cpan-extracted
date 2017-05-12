use strict;
use inc::Module::Install;

name            ('Encode-CN-Utility');
all_from        ('Encode/CN/Utility.pm');
license         ('perl');
build_requires  ('Test::More');
requires  ('Encode');

&WriteAll;
