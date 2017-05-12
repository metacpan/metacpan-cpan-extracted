use Test::More qw(no_plan);

use Math::Subsets::List;

my $a = '';

ok 8 == subsets {$a .= "@_\n"} qw(a b c);

ok $a eq << 'end';

c
b
b c
a
a c
a b
a b c
end

print $a;
