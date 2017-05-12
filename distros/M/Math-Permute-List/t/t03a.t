use Test::More qw(no_plan);

use Math::Permute::List;

my $a = '';

ok 6 == permute {$a .= "@_\n"} qw(a b c);

ok $a eq << 'end';
a b c
a c b
b a c
c a b
b c a
c b a
end

