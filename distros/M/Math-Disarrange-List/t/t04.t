use Test::More qw(no_plan);

use Math::Disarrange::List;

my $a = '';

ok 9 == disarrange {$a .= "@_\n"} 1..4;

ok $a eq << 'end';
2 1 4 3
4 1 2 3
3 1 4 2
2 4 1 3
3 4 1 2
4 3 1 2
2 3 4 1
3 4 2 1
4 3 2 1
end

