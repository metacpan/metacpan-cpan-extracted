use strict;
use Test::More tests => 2;

BEGIN { chdir '/tmp' };

use Find::Lib;

eval {
    Find::Lib->import('../mylib');
    eval "use MyLib a => 1, b => 42;"; die $@ if $@;
};
ok !$@, "we didn't die because chdir doesn't change PWD, so we are safe"
    or diag $@;
