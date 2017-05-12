use Test::More qw(no_plan);

use Math::Permute::List;

my $a = '';

ok 24 == permute {$a .= "@_\n"} 1..4;

ok $a eq << 'end';
1 2 3 4
1 2 4 3
1 3 2 4
1 4 2 3
1 3 4 2
1 4 3 2
2 1 3 4
2 1 4 3
3 1 2 4
4 1 2 3
3 1 4 2
4 1 3 2
2 3 1 4
2 4 1 3
3 2 1 4
4 2 1 3
3 4 1 2
4 3 1 2
2 3 4 1
2 4 3 1
3 2 4 1
4 2 3 1
3 4 2 1
4 3 2 1
end

