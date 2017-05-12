use strict;
use warnings;
use inc::Module::Install;

license  'Public Domain';
all_from 'lib/JS/JSON.pm';

requires 'JS' => '0.17';

WriteAll;
