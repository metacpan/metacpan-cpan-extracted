use 5.006;
use strict;
use warnings;

use inc::Module::Install;

name          ('HTTP-Sessioniser');
author        ('David Cannings <david@edeca.net>');
license       ('perl');
all_from      ('lib/HTTP/Sessioniser.pm');

#requires(URI => 1);
#requires(LWP => 5);
requires('IO::Compress::Gzip');
requires('HTTP::Parser');
requires('Net::LibNIDS' => '0.02'); # bugfixes

#extra_tests;

#install_script('bin/minicpan');

repository('http://github.com/edeca/HTTP-Sessioniser');
auto_manifest;

WriteAll;
