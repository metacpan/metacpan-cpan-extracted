use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Doorman.pm';
cpanfile;

tests 't/*.t';
author_tests 'xt';

WriteAll;
