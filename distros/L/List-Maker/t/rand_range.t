use Test::More 'no_plan';

use List::Maker;

for (1..100) {
    my $rand = < 2 r 7 >;
    ok $rand >= 2 && $rand <= 7       => "< 2 r 7 > rand $_ ($rand)";
}

for (1..100) {
    my $rand = < -2.2 r .7 >;
    ok $rand >= -2.2 && $rand <= 0.7  => "< -2.2 r .7 > rand $_ ($rand)";
}
