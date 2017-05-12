use Test::More qw(no_plan);

use Math::Disarrange::List;

my $a = '';

eval {disarrange {$a .= "@_\n"; die;} 1..2};


ok $a eq << 'end';
2 1
end

