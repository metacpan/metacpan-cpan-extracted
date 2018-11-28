use strict;
use warnings;
use Test::More tests => 3;

use_ok 'ExtUtils::F77';

is ExtUtils::F77->testcompiler, 1, 'testcompiler method returns 1';

is ExtUtils::F77->runtimeok, 1, 'runtime libs found';
