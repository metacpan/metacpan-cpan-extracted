use Test::More qw(no_plan);

use Math::Subsets::List;

my $a = '';

ok 8 == subsets {$a .= "@_\n"} 1..3;

ok $a eq << 'end';

3
2
2 3
1
1 3
1 2
1 2 3
end

