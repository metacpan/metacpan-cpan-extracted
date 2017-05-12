use strict;
use Test::More tests => 1;

# this screws everything :/
BEGIN { $0 = "[ren/am/med]" };

use Find::Lib;
eval {
    Find::Lib->import('../mylib');
    eval "use MyLib a => 1, b => 42;"; die $@ if $@;
};
chomp $@;
ok $@, "we die if \$0 ($0) doesn't make sense";
diag "ERROR was: $@";
