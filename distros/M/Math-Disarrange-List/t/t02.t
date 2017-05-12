use Test::More qw(no_plan);

use Math::Disarrange::List;

my $a = '';

ok 1 == disarrange {$a .= "@_\n"} 1..2;

ok $a eq << 'end';
2 1
end

