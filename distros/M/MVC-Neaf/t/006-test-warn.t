#!perl

use strict;
use warnings;
use Test::More tests => 1;

my $luck = eval {
    require Test::Warn;
    Test::Warn->import;
    1;
};
$luck or diag "Failed to load Test::Warn, subsequent tests may fail: $@";
ok 1; # and let it fail later
