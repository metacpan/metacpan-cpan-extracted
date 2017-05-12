use strict;
use inc::Module::Install;

name 'GD-Tab-Guitar';
all_from 'lib/GD/Tab/Guitar.pm';
 
perl_version '5.008001';
build_requires 'Test::More';
requires 'Class::Accessor::Fast';
requires 'List::Util';
requires 'GD' => 2.30;

WriteAll;
