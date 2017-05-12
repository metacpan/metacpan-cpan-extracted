use Test::More qw(no_plan);

use Math::Disarrange::List;

my $a = '';

ok 2 == disarrange {$a .= "@_\n"} 1..3;

ok $a eq << 'end';
3 1 2
2 3 1
end

