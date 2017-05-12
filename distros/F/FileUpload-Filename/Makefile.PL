use inc::Module::Install;

name            ('FileUpload-Filename');
abstract        ('Return the name of an uploaded file');
author          ('Florian Merges <fmerges@cpan.org>');
license         ('perl');
version_from    ('lib/FileUpload/Filename.pm');

requires        ('Carp');
requires        ('List::Util'          => '1.18');
requires        ('File::Basename'      => '2.73');
requires        ('HTTP::BrowserDetect' => '0.98');

build_requires  ('Test::More');

&WriteAll;
