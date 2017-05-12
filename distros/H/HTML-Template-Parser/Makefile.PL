use strict;
use warnings;

use inc::Module::Install;

all_from 'lib/HTML/Template/Parser.pm';

requires 'Parse::RecDescent' => 0;
requires 'Class::Accessor::Fast' => 0;
requires 'YAML' => 0;

tests_recursive;

WriteAll;


