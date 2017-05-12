use Test::More qw(no_plan);

use Math::Permute::Lists;

my $a = '';

ok 1 == permute {$a .= "@_\n"} 1;

ok $a eq << 'end';
1
end

