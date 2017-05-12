use Test::More qw(no_plan);

use Math::Subsets::List;

my $a = '';

ok 4 == subsets {$a .= "@_\n"} 1..2;

ok $a eq << 'end';

2
1
1 2
end
