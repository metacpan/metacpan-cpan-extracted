use Test::More qw(no_plan);

use Math::Subsets::List;

my $a = '';

ok 32 == subsets {$a .= "@_\n"} 1..5;

ok $a eq << 'end';

5
4
4 5
3
3 5
3 4
3 4 5
2
2 5
2 4
2 4 5
2 3
2 3 5
2 3 4
2 3 4 5
1
1 5
1 4
1 4 5
1 3
1 3 5
1 3 4
1 3 4 5
1 2
1 2 5
1 2 4
1 2 4 5
1 2 3
1 2 3 5
1 2 3 4
1 2 3 4 5
end

