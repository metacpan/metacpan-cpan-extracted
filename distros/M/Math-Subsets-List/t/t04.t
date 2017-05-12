use Test::More qw(no_plan);

use Math::Subsets::List;

my $a = '';

ok 16 == subsets {$a .= "@_\n"} 1..4;

print $a;
ok $a eq << 'end';

4
3
3 4
2
2 4
2 3
2 3 4
1
1 4
1 3
1 3 4
1 2
1 2 4
1 2 3
1 2 3 4
end

