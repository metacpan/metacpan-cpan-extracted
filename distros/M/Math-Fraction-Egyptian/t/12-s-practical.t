use strict;
use warnings;

#use Data::Dumper;
use Test::More 'no_plan';

use_ok('Math::Fraction::Egyptian');

local *s_practical = \&Math::Fraction::Egyptian::s_practical;

my @expansions = (
    [ 2, 9 => 0, 1, 6, 18 ],        # 2/9 => 1/6 + 1/18
);

for my $i (0 .. $#expansions) {
    my ($n1, $d1, @correct) = @{ $expansions[$i] };
    my ($n2, $d2, @e) = @correct;
    my @actual = s_practical($n1,$d1);
    is_deeply(
        \@actual,
        \@correct,
        "expanded $n1/$d1 to @actual, should be @correct"
    );
#   my $x1 = $n1 / $d1;
#   my $x2 = (1.0 / $e) + ($n2 / $d2);
#   cmp_ok(abs($x1 - $x2), q(<), 1e-9);
}

