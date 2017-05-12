use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'Inline-MonoCS';
perl_version '5.008005';
license 'perl';
all_from 'lib/Inline/MonoCS.pm';

test_requires 'Test::More'  => 0;
requires    'Digest::MD5'   => 0;
requires_external_bin 'gmcs';

tests_recursive();
WriteAll();

