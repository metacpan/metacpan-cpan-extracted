#!/usr/bin/env perl

use inc::Module::Install;

name 'File-MimeInfo-Simple';

perl_version '5.005';

all_from 'lib/File/MimeInfo/Simple.pm';

license 'MIT';

requires 'File::Slurp' => '0';
requires 'YAML::Syck' => '0';
test_requires 'Test::More' => '0';

WriteAll;
