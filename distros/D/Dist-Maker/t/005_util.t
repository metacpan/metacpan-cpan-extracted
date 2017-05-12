#!perl -w
use strict;
use Test::More;

use Dist::Maker::Util;
use List::Util qw(first);

my @templates = available_templates();

note explain \@templates;

foreach my $t(qw(Default Moose Mouse Any::Moose XS CLI)) {
    ok first(sub{ $_ eq $t }, @templates), $t;
}

done_testing;

