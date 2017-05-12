#!perl
use strict;

use Test::More tests => 15;

BEGIN { use_ok('Math::Random::Discrete'); }

my @weights = (10, 9, 8, 7, 6, 5, 4, 3, 2, 1);
my $sum = 55;

my $gen = new_ok('Math::Random::Discrete' => [
    \@weights,
    [ qw(a b c d e f g h i j) ],
]);

my $N = @{ $gen->{F} };
is($N, 10, 'array len');

my @actual_weights = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

for (my $i = 0; $i < $N; ++$i) {
    my $A = $gen->{A}[$i];
    my $F = $gen->{F}[$i];

    $actual_weights[$i] += $F;
    $actual_weights[$A] += 1 - $F;
}

my $error_sum  = 0;
my $avg_weight = $sum / $N;

for (my $i = 0; $i < $N; ++$i) {
    $error_sum += abs($weights[$i] - $avg_weight * $actual_weights[$i]);
}

ok($error_sum < 1e-9, 'actual weights');

my @counts = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
my $chars_ok = 1;

for (my $j = 0; $j < 1_000 * $sum; ++$j) {
    my $char = $gen->rand;

    $chars_ok = undef
        if $char !~ /^[a-j]\z/;

    my $i = ord($char) - 97;
    ++$counts[$i];
}

ok($chars_ok, 'result chars');

# the following tests can actually fail with a low probability

for (my $i = 0; $i < $N; ++$i) {
    my $expected = (10 - $i) * 1_000;
    my $diff = abs($counts[$i] - $expected);
    ok($diff < 500, "counts for item $i");
}

