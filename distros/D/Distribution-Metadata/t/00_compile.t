use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Distribution::Metadata
);

ok !system $^X, "-Ilib", "-wc", "script/which-meta";

done_testing;

