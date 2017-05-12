use Test::More qw(no_plan);

use Math::Subsets::List;

my $a = '';

ok 2 == subsets {$a .= "@_\n"} 1..1;

ok $a eq << 'end';

1
end
