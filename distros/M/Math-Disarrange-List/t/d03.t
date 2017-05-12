use Test::More qw(no_plan);

use Math::Disarrange::List;

my $a = '';

ok 2 == disarrange {$a .= "@_\n"} qw(a b c);

ok $a eq << 'end';
c a b
b c a
end

