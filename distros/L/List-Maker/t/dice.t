use Test::More 'no_plan';

use List::Maker;

for (1..100) {
    my $roll = < 2 d 7 >;
    ok $roll >= 2 && $roll <= 14      => "< 2 d 7 > roll $_ ($roll)";
}

for (1..100) {
    my $roll = < 7d2 >;
    ok $roll >= 7 && $roll <= 14      => "< 7d2 > roll $_ ($roll)";
}

for (1..100) {
    my $roll = < 3d4.0 >;
    ok $roll >= 0 && $roll < 12      => "< 3d4.0 > roll $_ ($roll)";
}

for (1..100) {
    my @rolls = < 3 d 12 >;
    is scalar @rolls, 3                   => 'list context count';
    for my $roll (@rolls) {
        ok $roll >= 1 && $roll <= 12      => "list context element ($roll)";
    }
}

for (1..100) {
    my @rolls = < 3.7 d 12.3 >;
    is scalar @rolls, 4                   => 'list context count';
    for my $roll (@rolls) {
        ok $roll >= 0 && $roll < 12.3    => "list context element ($roll)";
    }
}
