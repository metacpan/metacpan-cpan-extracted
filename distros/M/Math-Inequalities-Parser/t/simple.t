use strict;
use warnings;
use Test::More 0.88;

use Math::Inequalities::Parser;

my %tests = (
    # Inequality  # Min Max
    '11<n'     => [12, undef],
    '11>n'     => [undef, 10],
    'n>11'     => [12, undef],
    'n<11'     => [undef, 10],
    '2<n<11'   => [3, 10],
    '42'       => [42, 42],
    '11<=n'     => [11, undef],
    '11>=n'     => [undef, 11],
    'n>=11'     => [11, undef],
    'n<=11'     => [undef, 11],
    ''          => [undef, undef],
    '    '      => [undef, undef],
);

foreach my $t (keys %tests) {
    $tests{" $t"} = [ @{ $tests{$t} } ];
    $tests{"$t "} = [ @{ $tests{$t} } ];
    $tests{" $t "} = [ @{ $tests{$t} } ];
}

is_deeply [parse_inequality(undef)],
    [undef, undef], 'check undef';

foreach my $t (keys %tests) {
    is_deeply [parse_inequality($t)],
        $tests{$t}, "check '$t'";
}

done_testing;
