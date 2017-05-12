use Test::More qw(no_plan);

use Math::Permute::Lists;

my $a = '';

ok 6 == permute {$a .= "@_\n"} qw(a b c);

ok $a eq << 'end';
a b c
a c b
b a c
b c a
c a b
c b a
end

