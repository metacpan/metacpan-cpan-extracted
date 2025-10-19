# Before 'make install' is performed this script should be runnable with
# 'make test'

#########################

use strict;
use warnings;

use Test::More;
my $perl_modules = [sort map { s{/+}{::}g; $_; } `cat MANIFEST` =~ m{^lib/(.+)\.pm$}gm];
plan tests => 0+@$perl_modules;
foreach my $mod (@$perl_modules) {
    use_ok($mod);
}
