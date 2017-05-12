use strict;
use Test::More tests => 2;

use Find::Lib;

BEGIN { chdir '/tmp' };

eval { 
    Find::Lib->import('../mylib');
    eval "use MyLib a => 1, b => 42;"; die $@ if $@;
};
ok ! $@, "we didn't die, because initial Find::Lib compilation saved cwd";

