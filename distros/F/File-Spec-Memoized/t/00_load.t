#!perl -w

use strict;
use Test::More tests => 1;

BEGIN { use_ok 'File::Spec::Memoized' }

diag "Testing File::Spec::Memoized/$File::Spec::Memoized::VERSION";

diag "Dependencies:";
diag "File::Spec/$File::Spec::VERSION (@File::Spec::Memoized::ISA)";
