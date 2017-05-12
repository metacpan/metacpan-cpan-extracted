use Test::More qw(no_plan);

use Math::Permute::List;

my $a = '';

ok 2 == permute {$a .= "@_\n"} 1..2;

ok $a eq << 'end';
1 2
2 1
end

