use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/JS/Chicken.pm';

requires 'JS'         => '0.17';
requires 'JS::jQuery' => '0';

WriteAll;
