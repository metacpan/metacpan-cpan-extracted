use Test::More qw(no_plan);

use Math::Subsets::List;

my $a = '';

eval {subsets {$a .= "@_\n"; die;} 1..2};

ok $a eq << 'end';

end
