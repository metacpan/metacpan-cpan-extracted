use strict;
use inc::Module::Install;

name           'JSAN-Parse-FileDeps';
all_from       'lib/JSAN/Parse/FileDeps.pm';
requires       'File::Spec' => '0.80';
build_requires 'Test::More' => '0.47';

WriteAll;
