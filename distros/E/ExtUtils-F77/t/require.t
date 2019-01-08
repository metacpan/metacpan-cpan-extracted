use strict;
use warnings;
use File::Which qw(which);
use Test::More tests => 3;

$ExtUtils::F77::DEBUG = $ExtUtils::F77::DEBUG = 1;

my $mod = 'ExtUtils::F77';
use_ok $mod;

is $mod->testcompiler, 1, 'testcompiler method returns 1';

is $mod->runtimeok, 1, 'runtime libs found';

diag "Method: $_, ", explain $mod->$_ for qw(runtime trail_ compiler cflags);

diag "Compiler: ", which $mod->compiler;
