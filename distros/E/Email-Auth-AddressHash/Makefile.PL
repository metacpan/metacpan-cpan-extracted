use inc::Module::Install;

name            ('Email-Auth-AddressHash');
abstract        ('Email extension hash authentication mechanism');
author          ('Tara Andrews <tla@mit.edu>');
version_from    ('lib/Email/Auth/AddressHash.pm');
license         ('perl');

requires        ('perl' => 5.005);
requires        ('Digest::MD5');
build_requires  ('Test::More');

&WriteAll;
