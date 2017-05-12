use Test::More qw(no_plan);

use Math::Permute::Lists;

my $a = '';

ok 6 == permute {$a .= "@_\n"} 1..3;

ok $a eq << 'end';
1 2 3
1 3 2
2 1 3
2 3 1
3 1 2
3 2 1
end

