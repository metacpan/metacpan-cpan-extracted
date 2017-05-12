use strict;
use warnings;
use inc::Module::Install;

name 'Markaya';
all_from 'lib/Markaya.pm';

requires 'HTML::Entities' => 0;
requires 'YAML::XS' => 0.16;

build_requires  'Test::More'        => '0.42';

WriteAll;


